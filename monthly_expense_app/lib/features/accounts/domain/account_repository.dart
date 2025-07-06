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

  // Get a single account by ID
  Future<Account?> getAccount(String accountId) async {
    try {
      final doc = await _collection.doc(accountId).get();
      if (doc.exists) {
        return Account.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update account balance
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _collection.doc(accountId).update({
        'balance': newBalance,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }
} 