import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart';

class TransactionRepository {
  final _collection = FirebaseFirestore.instance.collection('transactions');

  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _collection.add(transaction.toFirestore());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _collection.doc(transaction.id).update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _collection.doc(transactionId).delete();
  }
} 