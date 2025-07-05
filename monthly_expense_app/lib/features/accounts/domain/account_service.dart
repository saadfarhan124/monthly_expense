import 'account_repository.dart';
import 'account_model.dart';

class AccountService {
  final AccountRepository _repo;
  AccountService(this._repo);

  Stream<List<Account>> getAccounts(String userId) => _repo.getAccounts(userId);
  Future<void> addAccount(Account account) => _repo.addAccount(account);
  Future<void> updateAccount(Account account) => _repo.updateAccount(account);
  Future<void> deleteAccount(String accountId) => _repo.deleteAccount(accountId);
} 