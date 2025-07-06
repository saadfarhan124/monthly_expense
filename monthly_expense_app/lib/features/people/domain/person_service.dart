import 'person_repository.dart';
import 'person_model.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_repository.dart';

class PersonService {
  final PersonRepository _personRepository;
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  PersonService(this._personRepository, this._transactionRepository, this._accountRepository)
      : _categoryRepository = CategoryRepository();

  /// Find category ID by name
  Future<String?> _findCategoryIdByName(String userId, String categoryName) async {
    try {
      final categories = await _categoryRepository.getCategories(userId).first;
      final category = categories.firstWhere(
        (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
        orElse: () => throw Exception('Category not found'),
      );
      return category.id;
    } catch (e) {
      return null;
    }
  }

  /// Lend money to a person
  Future<bool> lendMoney({
    required String userId,
    required String accountId,
    required String personId,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    try {
      // Get account and person details
      final account = await _accountRepository.getAccount(accountId);
      final person = await _personRepository.getPerson(personId);
      
      if (account == null) {
        throw Exception('Account not found');
      }
      
      if (person == null) {
        throw Exception('Person not found');
      }
      
      if (account.balance < amount) {
        throw Exception('Insufficient balance in account');
      }
      
      // Find category ID
      final lendingCategoryId = await _findCategoryIdByName(userId, 'Lending');
      
      // Create the lending transaction
      final lendingTransaction = TransactionModel(
        id: '',
        accountId: accountId,
        categoryId: lendingCategoryId ?? 'lending',
        amount: amount,
        description: description,
        type: TransactionType.lend,
        userId: userId,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        personId: personId,
      );
      
      // Add the transaction
      await _transactionRepository.addTransaction(lendingTransaction);
      
      // Update account balance (decrease)
      await _accountRepository.updateAccountBalance(
        accountId, 
        account.balance - amount
      );
      
      // Update person balance (they owe you more)
      await _personRepository.updatePersonBalance(
        personId, 
        person.balance + amount
      );
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Borrow money from a person
  Future<bool> borrowMoney({
    required String userId,
    required String accountId,
    required String personId,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    try {
      // Get account and person details
      final account = await _accountRepository.getAccount(accountId);
      final person = await _personRepository.getPerson(personId);
      
      if (account == null) {
        throw Exception('Account not found');
      }
      
      if (person == null) {
        throw Exception('Person not found');
      }
      
      // Find category ID
      final borrowingCategoryId = await _findCategoryIdByName(userId, 'Borrowing');
      
      // Create the borrowing transaction
      final borrowingTransaction = TransactionModel(
        id: '',
        accountId: accountId,
        categoryId: borrowingCategoryId ?? 'borrowing',
        amount: amount,
        description: description,
        type: TransactionType.borrow,
        userId: userId,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        personId: personId,
      );
      
      // Add the transaction
      await _transactionRepository.addTransaction(borrowingTransaction);
      
      // Update account balance (increase)
      await _accountRepository.updateAccountBalance(
        accountId, 
        account.balance + amount
      );
      
      // Update person balance (you owe them more)
      await _personRepository.updatePersonBalance(
        personId, 
        person.balance - amount
      );
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all people for a user
  Stream<List<Person>> getPeople(String userId) {
    return _personRepository.getPeople(userId);
  }

  /// Add a new person
  Future<void> addPerson(Person person) async {
    await _personRepository.addPerson(person);
  }

  /// Update a person
  Future<void> updatePerson(Person person) async {
    await _personRepository.updatePerson(person);
  }

  /// Delete a person
  Future<void> deletePerson(String personId) async {
    await _personRepository.deletePerson(personId);
  }

  /// Get a specific person
  Future<Person?> getPerson(String personId) async {
    return await _personRepository.getPerson(personId);
  }

  /// Get lending/borrowing transactions for a person
  Stream<List<TransactionModel>> getPersonTransactions(String personId) {
    return _transactionRepository.getTransactionsByAccount(personId)
        .map((transactions) => transactions
            .where((t) => t.type == TransactionType.lend || t.type == TransactionType.borrow)
            .toList());
  }

  /// Calculate total amount owed to you by all people
  Future<double> getTotalOwedToYou(String userId) async {
    final people = await getPeople(userId).first;
    return people.fold<double>(0.0, (sum, person) => sum + (person.balance > 0 ? person.balance : 0));
  }

  /// Calculate total amount you owe to all people
  Future<double> getTotalYouOwe(String userId) async {
    final people = await getPeople(userId).first;
    return people.fold<double>(0.0, (sum, person) => sum + (person.balance < 0 ? person.balance.abs() : 0));
  }
} 