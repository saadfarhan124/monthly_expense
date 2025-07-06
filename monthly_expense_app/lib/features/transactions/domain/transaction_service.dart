import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart';
import 'transaction_repository.dart';
import '../../accounts/domain/account_model.dart';

class TransactionService {
  final TransactionRepository _repo;

  TransactionService(this._repo);

  Stream<List<TransactionModel>> getTransactions(String userId) => _repo.getTransactions(userId);
  Future<void> updateTransaction(TransactionModel transaction) => _repo.updateTransaction(transaction);
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
      // Find the fee transaction by looking for expense transactions with matching description
      final feeDescription = 'Transfer fee for: ${transfer.description}';
      
      final query = await FirebaseFirestore.instance
          .collection('transactions')
          .where('accountId', isEqualTo: transfer.accountId)
          .where('type', isEqualTo: 'expense')
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