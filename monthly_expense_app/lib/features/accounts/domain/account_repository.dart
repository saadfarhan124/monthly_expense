import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_model.dart';

class AccountRepository {
  final _collection = FirebaseFirestore.instance.collection('accounts');

  Stream<List<Account>> getAccounts(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addAccount(Account account) async {
    await _collection.add(account.toFirestore());
  }

  Future<void> updateAccount(Account account) async {
    await _collection.doc(account.id).update(account.toFirestore());
  }

  Future<void> deleteAccount(String accountId) async {
    await _collection.doc(accountId).delete();
  }
} 