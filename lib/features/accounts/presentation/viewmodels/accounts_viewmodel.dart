import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/account_model.dart';
import '../../data/accounts_repository.dart';

class AccountsViewModel extends BaseViewModel {
  final AccountsRepository _repo;
  AccountsViewModel(this._repo);

  List<Account> accounts = [];

  Future<void> load() async {
    setBusy(true);
    try {
      accounts = await _repo.listAccounts();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }
}
