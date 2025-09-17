import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/social_models.dart';
import '../../data/social_repository.dart';

class SocialViewModel extends BaseViewModel {
  final SocialRepository _repo;
  SocialViewModel(this._repo);

  SocialBalance? balance;
  List<SocialContribution> contributions = [];
  int? activeMeetingFilter;

  Future<void> load(int cycleId) async {
    setBusy(true);
    try {
      final data = await _repo.load(cycleId);
      balance = data.$1;
      contributions = data.$2;
      activeMeetingFilter = null;
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadAll(int cycleId) async {
    await load(cycleId);
  }

  Future<void> loadForMeeting({
    required int meetingId,
    required int cycleId,
  }) async {
    setBusy(true);
    try {
      final data = await _repo.load(cycleId);
      final all = data.$2;
      contributions = all.where((c) => c.meetingId == meetingId).toList();
      final total = contributions.fold<int>(0, (sum, it) => sum + it.amount);
      balance = SocialBalance(cycleId: cycleId, balance: total);
      activeMeetingFilter = meetingId;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<bool> addContribution({
    required int meetingId,
    required int memberId,
    required int amount,
    required DateTime date,
  }) async {
    setBusy(true);
    setError(null);
    try {
      await _repo.addContribution(
        meetingId: meetingId,
        memberId: memberId,
        amount: amount,
        date: date,
      );
      return true;
    } catch (e) {
      setError('Failed to add contribution');
      return false;
    } finally {
      setBusy(false);
    }
  }
}
