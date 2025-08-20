import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/transaction_models.dart';
import '../../data/transactions_repository.dart';

class TransactionsViewModel extends BaseViewModel {
  final TransactionsRepository _repo;
  TransactionsViewModel(this._repo);

  List<TransactionRecord> transactions = [];
  TransactionType? activeFilter;
  int? _lastCycleId;

  Future<void> load(int cycleId, {TransactionType? filter}) async {
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      _lastCycleId = cycleId;
      activeFilter = filter;
      transactions = await _repo.listAll(cycleId: cycleId, filter: filter);
      
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  void clearFilter() {
    if (busy) return;
    if (_lastCycleId == null) return;
    // Reset filter and reload using the last cycle id
    // Important: don't set busy here; delegate to load()
    load(_lastCycleId!, filter: null);
  }
}
