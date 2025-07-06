import 'transaction_model.dart';
import 'transaction_repository.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_repository.dart';

class TransferService {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  TransferService(this._transactionRepository, this._accountRepository)
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

  /// Create a transfer between accounts
  /// Returns true if successful, throws exception if failed
  Future<bool> createTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String description,
    double? exchangeRate,
    double? transferFee,
    String? transferFeeCurrency,
    DateTime? date,
  }) async {
    try {
      // Get account details
      final fromAccount = await _accountRepository.getAccount(fromAccountId);
      final toAccount = await _accountRepository.getAccount(toAccountId);
      
      if (fromAccount == null || toAccount == null) {
        throw Exception('One or both accounts not found');
      }
      
      if (fromAccount.id == toAccount.id) {
        throw Exception('Cannot transfer to the same account');
      }
      
      // Validate currencies and exchange rate
      final isCrossCurrency = fromAccount.currency != toAccount.currency;
      if (isCrossCurrency && exchangeRate == null) {
        throw Exception('Exchange rate is required for cross-currency transfers');
      }
      
      if (isCrossCurrency && exchangeRate! <= 0) {
        throw Exception('Exchange rate must be greater than 0');
      }
      
      // Validate transfer fee
      if (transferFee != null && transferFee < 0) {
        throw Exception('Transfer fee cannot be negative');
      }
      
      // Calculate effective amounts
      final effectiveAmount = amount + (transferFee ?? 0.0);
      final destinationAmount = isCrossCurrency ? amount * exchangeRate! : amount;
      
      // Check if source account has sufficient balance
      if (fromAccount.balance < effectiveAmount) {
        throw Exception('Insufficient balance in source account');
      }
      
      // Find category IDs
      final transferCategoryId = await _findCategoryIdByName(userId, 'Transfer');
      final transferFeesCategoryId = await _findCategoryIdByName(userId, 'Transfer Fees');
      
      // Create the transfer transaction
      final transferTransaction = TransactionModel(
        id: '',
        accountId: fromAccountId,
        categoryId: transferCategoryId ?? '', // Use actual Transfer category ID
        amount: amount,
        description: description,
        type: TransactionType.transfer,
        userId: userId,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        toAccountId: toAccountId,
        exchangeRate: exchangeRate,
        transferFee: transferFee,
        transferFeeCurrency: transferFeeCurrency ?? fromAccount.currency,
      );
      
      // Add the transfer transaction
      await _transactionRepository.addTransaction(transferTransaction);
      
      // If there's a transfer fee, create an expense transaction for it
      if (transferFee != null && transferFee > 0) {
        final feeTransaction = TransactionModel(
          id: '',
          accountId: fromAccountId,
          categoryId: transferFeesCategoryId ?? '', // Use actual Transfer Fees category ID
          amount: transferFee,
          description: 'Transfer fee for: $description',
          type: TransactionType.expense,
          userId: userId,
          date: date ?? DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _transactionRepository.addTransaction(feeTransaction);
      }
      
      // Update account balances
      await _accountRepository.updateAccountBalance(
        fromAccountId, 
        fromAccount.balance - effectiveAmount
      );
      
      await _accountRepository.updateAccountBalance(
        toAccountId, 
        toAccount.balance + destinationAmount
      );
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get transfer history for an account
  Stream<List<TransactionModel>> getTransferHistory(String accountId) {
    return _transactionRepository.getTransactionsByAccount(accountId)
        .map((transactions) => transactions
            .where((t) => t.type == TransactionType.transfer)
            .toList());
  }

  /// Get all transfers for a user
  Stream<List<TransactionModel>> getAllTransfers(String userId) {
    return _transactionRepository.getTransactions(userId)
        .map((transactions) => transactions
            .where((t) => t.type == TransactionType.transfer)
            .toList());
  }

  /// Calculate transfer statistics
  Future<TransferStatistics> getTransferStatistics(String userId) async {
    final transfers = await getAllTransfers(userId).first;
    
    double totalTransferred = 0.0;
    double totalFees = 0.0;
    int transferCount = transfers.length;
    
    for (final transfer in transfers) {
      totalTransferred += transfer.amount;
      totalFees += transfer.transferFee ?? 0.0;
    }
    
    return TransferStatistics(
      totalTransferred: totalTransferred,
      totalFees: totalFees,
      transferCount: transferCount,
    );
  }
}

/// Statistics for transfers
class TransferStatistics {
  final double totalTransferred;
  final double totalFees;
  final int transferCount;

  const TransferStatistics({
    required this.totalTransferred,
    required this.totalFees,
    required this.transferCount,
  });
} 