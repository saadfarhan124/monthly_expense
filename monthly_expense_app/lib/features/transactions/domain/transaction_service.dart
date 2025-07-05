import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart';
import 'transaction_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/domain/account_repository.dart';

class TransactionService {
  final TransactionRepository _repo;
  final AccountRepository _accountRepo;

  TransactionService(this._repo, this._accountRepo);

  Stream<List<TransactionModel>> getTransactions(String userId) => _repo.getTransactions(userId);
  Future<void> updateTransaction(TransactionModel transaction) => _repo.updateTransaction(transaction);
  Future<void> deleteTransaction(String transactionId) async {
    try {
      // Get the transaction before deleting it
      final transaction = await _getTransaction(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      // Delete the transaction
      await _repo.deleteTransaction(transactionId);
      
      // Update account balance (reverse the transaction effect)
      await _reverseAccountBalance(transaction);
    } catch (e) {
      print('Error deleting transaction: $e');
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
      print('Error adding transaction: $e');
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
      print('Error getting account: $e');
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
      print('Error getting transaction: $e');
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
      print('Error reversing account balance: $e');
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
      print('Error updating account balance: $e');
    }
  }
} 