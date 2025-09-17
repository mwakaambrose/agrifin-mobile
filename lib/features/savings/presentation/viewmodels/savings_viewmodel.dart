import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/savings_models.dart';
import '../../data/savings_repository.dart';

class SavingsViewModel extends BaseViewModel {
  final SavingsRepository _repo;
  SavingsViewModel(this._repo);

  SavingsAccountSummary? summary;
  List<SavingsTransaction> transactions = [];
  int? activeMeetingFilter;

  Future<void> load(int cycleId) async {
    setBusy(true);
    try {
      summary = await _repo.getSummary(cycleId);
      transactions = await _repo.getTransactions(cycleId: cycleId);
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadForMeeting(int meetingId) async {
    setBusy(true);
    setError(null);
    try {
      final data = await _repo.getForMeeting(meetingId);
      summary = data.summary;
      transactions = data.transactions;
      activeMeetingFilter = meetingId;
      notifyListeners();
    } catch (e) {
      setError('Failed to load savings');
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadAll({int? cycleId}) async {
    setBusy(true);
    setError(null);
    try {
      final data = await _repo.getAll(cycleId: cycleId);
      summary = data.summary;
      transactions = data.transactions;
      activeMeetingFilter = null;
      notifyListeners();
    } catch (e) {
      setError('Failed to load savings');
    } finally {
      setBusy(false);
    }
  }

  void clearFilter() {
    activeMeetingFilter = null;
    notifyListeners();
  }

  Future<bool> contribute({
    required int memberId,
    required int amount,
    required int meetingId,
    String? note,
  }) async {
    setBusy(true);
    setError(null);
    try {
      await _repo.contributeToMeeting(
        meetingId: meetingId,
        memberId: memberId,
        amount: amount,
        note: note,
      );
      return true;
    } catch (e) {
      setError('Failed to contribute');
      return false;
    } finally {
      setBusy(false);
    }
  }
}
