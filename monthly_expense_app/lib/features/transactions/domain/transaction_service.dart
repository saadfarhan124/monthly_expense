import 'transaction_repository.dart';
import 'transaction_model.dart';

class TransactionService {
  final TransactionRepository _repo;
  TransactionService(this._repo);

  Stream<List<TransactionModel>> getTransactions(String userId) => _repo.getTransactions(userId);
  Future<void> addTransaction(TransactionModel transaction) => _repo.addTransaction(transaction);
  Future<void> updateTransaction(TransactionModel transaction) => _repo.updateTransaction(transaction);
  Future<void> deleteTransaction(String transactionId) => _repo.deleteTransaction(transactionId);
} 