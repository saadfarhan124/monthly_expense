import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart';
import 'transaction_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../categories/domain/category_repository.dart';
import '../../people/domain/person_model.dart';

class TransactionService {
  final TransactionRepository _repo;
  final CategoryRepository _categoryRepo;

  TransactionService(this._repo) : _categoryRepo = CategoryRepository();

  Stream<List<TransactionModel>> getTransactions(String userId) => _repo.getTransactions(userId);
  
  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    try {
      // Get the original transaction to calculate balance changes
      final originalTransaction = await _getTransaction(updatedTransaction.id);
      if (originalTransaction == null) {
        throw Exception('Transaction not found');
      }

      // Don't allow editing transfer transactions
      if (originalTransaction.type == TransactionType.transfer) {
        throw Exception('Transfer transactions cannot be edited');
      }

      // Check if account has sufficient balance for expenses
      if (updatedTransaction.type == TransactionType.expense) {
        final account = await _getAccount(updatedTransaction.accountId);
        if (account == null) {
          throw Exception('Account not found');
        }
        
        // Calculate the difference in amount
        final amountDifference = updatedTransaction.amount - originalTransaction.amount;
        final newBalance = account.balance - amountDifference;
        
        if (newBalance < 0) {
          throw Exception('Insufficient funds. Available: ${account.currency} ${account.balance.toStringAsFixed(2)}');
        }
      }

      // Update the transaction
      await _repo.updateTransaction(updatedTransaction);
      
      // Update account balances
      await _updateAccountBalanceForEdit(originalTransaction, updatedTransaction);
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Find category ID by name
  Future<String?> _findCategoryIdByName(String userId, String categoryName) async {
    try {
      final categories = await _categoryRepo.getCategories(userId).first;
      final category = categories.firstWhere(
        (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
        orElse: () => throw Exception('Category not found'),
      );
      return category.id;
    } catch (e) {
      return null;
    }
  }
  Future<void> deleteTransaction(String transactionId) async {
    try {
      // Get the transaction before deleting it
      final transaction = await _getTransaction(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      // If this is a transfer, handle it specially
      if (transaction.type == TransactionType.transfer) {
        await _deleteTransfer(transaction);
      } else if (transaction.type == TransactionType.lend || transaction.type == TransactionType.borrow) {
        await _deletePersonTransaction(transaction);
      } else {
        // Delete the transaction
        await _repo.deleteTransaction(transactionId);
        
        // Update account balance (reverse the transaction effect)
        await _reverseAccountBalance(transaction);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      // Check if account has sufficient balance for expenses
      if (transaction.type == TransactionType.expense) {
        final account = await _getAccount(transaction.accountId);
        if (account == null) {
          throw Exception('Account not found');
        }
        
        if (account.balance < transaction.amount) {
          throw Exception('Insufficient funds. Available: ${account.currency} ${account.balance.toStringAsFixed(2)}');
        }
      }

      // Add the transaction
      await _repo.addTransaction(transaction);
      
      // Update account balance
      await _updateAccountBalance(transaction);
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Account?> _getAccount(String accountId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(accountId)
          .get();
      
      if (doc.exists) {
        return Account.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<TransactionModel?> _getTransaction(String transactionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (doc.exists) {
        return TransactionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _reverseAccountBalance(TransactionModel transaction) async {
    try {
      final account = await _getAccount(transaction.accountId);
      if (account == null) return;

      double newBalance = account.balance;
      // Reverse the transaction effect
      if (transaction.type == TransactionType.income) {
        newBalance -= transaction.amount; // Remove income
      } else {
        newBalance += transaction.amount; // Add back expense
      }

      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(transaction.accountId)
          .update({'balance': newBalance});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateAccountBalance(TransactionModel transaction) async {
    try {
      final account = await _getAccount(transaction.accountId);
      if (account == null) return;

      double newBalance = account.balance;
      if (transaction.type == TransactionType.income) {
        newBalance += transaction.amount;
      } else {
        newBalance -= transaction.amount;
      }

      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(transaction.accountId)
          .update({'balance': newBalance});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateAccountBalanceForEdit(TransactionModel original, TransactionModel updated) async {
    try {
      // Handle original account balance (reverse the original transaction)
      final originalAccount = await _getAccount(original.accountId);
      if (originalAccount != null) {
        double originalBalance = originalAccount.balance;
        if (original.type == TransactionType.income) {
          originalBalance -= original.amount; // Remove original income
        } else {
          originalBalance += original.amount; // Add back original expense
        }
        
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(original.accountId)
            .update({'balance': originalBalance});
      }

      // Handle updated account balance (apply the new transaction)
      final updatedAccount = await _getAccount(updated.accountId);
      if (updatedAccount != null) {
        double updatedBalance = updatedAccount.balance;
        if (updated.type == TransactionType.income) {
          updatedBalance += updated.amount; // Add new income
        } else {
          updatedBalance -= updated.amount; // Subtract new expense
        }
        
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(updated.accountId)
            .update({'balance': updatedBalance});
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deletePersonTransaction(TransactionModel transaction) async {
    try {
      // Get account and person details
      final account = await _getAccount(transaction.accountId);
      final person = await _getPerson(transaction.personId!);
      
      if (account == null) {
        throw Exception('Account not found');
      }
      
      if (person == null) {
        throw Exception('Person not found');
      }

      // Delete the transaction
      await _repo.deleteTransaction(transaction.id);

      // Reverse account balance
      if (transaction.type == TransactionType.lend) {
        // Lend: account balance was decreased, so add it back
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(transaction.accountId)
            .update({'balance': account.balance + transaction.amount});
        
        // Person balance was increased (they owe you more), so decrease it
        await FirebaseFirestore.instance
            .collection('people')
            .doc(transaction.personId)
            .update({'balance': person.balance - transaction.amount});
      } else if (transaction.type == TransactionType.borrow) {
        // Borrow: account balance was increased, so subtract it back
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(transaction.accountId)
            .update({'balance': account.balance - transaction.amount});
        
        // Person balance was decreased (you owe them more), so increase it
        await FirebaseFirestore.instance
            .collection('people')
            .doc(transaction.personId)
            .update({'balance': person.balance + transaction.amount});
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Person?> _getPerson(String personId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('people')
          .doc(personId)
          .get();
      
      if (doc.exists) {
        return Person.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _deleteTransfer(TransactionModel transfer) async {
    try {
      // Get account details
      final fromAccount = await _getAccount(transfer.accountId);
      final toAccount = await _getAccount(transfer.toAccountId!);
      
      if (fromAccount == null || toAccount == null) {
        throw Exception('One or both accounts not found');
      }

      // Calculate amounts to reverse
      final isCrossCurrency = fromAccount.currency != toAccount.currency;
      final destinationAmount = isCrossCurrency && transfer.exchangeRate != null
          ? transfer.amount * transfer.exchangeRate!
          : transfer.amount;
      final effectiveAmount = transfer.amount + (transfer.transferFee ?? 0.0);

      // Find and delete the associated fee transaction
      if (transfer.transferFee != null && transfer.transferFee! > 0) {
        await _deleteTransferFeeTransaction(transfer);
      }

      // Delete the transfer transaction
      await _repo.deleteTransaction(transfer.id);

      // Reverse account balances
      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(transfer.accountId)
          .update({'balance': fromAccount.balance + effectiveAmount});

      await FirebaseFirestore.instance
          .collection('accounts')
          .doc(transfer.toAccountId!)
          .update({'balance': toAccount.balance - destinationAmount});

    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteTransferFeeTransaction(TransactionModel transfer) async {
    try {
      // Find the fee transaction by looking for expense transactions with matching description and category
      final feeDescription = 'Transfer fee for: ${transfer.description}';
      
      // Find the Transfer Fees category ID
      final transferFeesCategoryId = await _findCategoryIdByName(transfer.userId, 'Transfer Fees');
      
      if (transferFeesCategoryId == null) {
        // If category not found, just look by description and amount
        final query = await FirebaseFirestore.instance
            .collection('transactions')
            .where('accountId', isEqualTo: transfer.accountId)
            .where('type', isEqualTo: 'expense')
            .where('description', isEqualTo: feeDescription)
            .where('amount', isEqualTo: transfer.transferFee)
            .get();
            
        if (query.docs.isNotEmpty) {
          await _repo.deleteTransaction(query.docs.first.id);
        }
        return;
      }
      
      final query = await FirebaseFirestore.instance
          .collection('transactions')
          .where('accountId', isEqualTo: transfer.accountId)
          .where('type', isEqualTo: 'expense')
          .where('categoryId', isEqualTo: transferFeesCategoryId)
          .where('description', isEqualTo: feeDescription)
          .where('amount', isEqualTo: transfer.transferFee)
          .get();

      if (query.docs.isNotEmpty) {
        // Delete the fee transaction
        await _repo.deleteTransaction(query.docs.first.id);
      }
    } catch (e) {
      rethrow;
    }
  }
} 