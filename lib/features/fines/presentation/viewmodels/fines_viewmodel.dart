import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/fines_models.dart';
import '../../data/fines_repository.dart';

class FinesViewModel extends BaseViewModel {
  final FinesRepository _repo;
  FinesViewModel(this._repo);

  List<FineType> types = [];
  List<FineRecord> records = [];
  bool initialized = false;

  Future<void> load(int cycleId, int meetingId) async {
    setBusy(true);
    try {
      final data = await _repo.load(cycleId: cycleId, meetingId: meetingId);
      types = data.$1;
      records = data.$2;
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
      initialized =
          true; // mark that we attempted a load so UI won't auto-retry
    }
  }

  Future<void> ensureLoaded(int cycleId, int meetingId) async {
    if (initialized) return;
    await load(cycleId, meetingId);
  }

  Future<void> assignFine({
    required int memberId,
    required FineType type,
    required DateTime date,
  }) async {
    // Post to API then optimistically update UI
    try {
      // We don't have meetingId here; assign through repository is better used in screen with meetingId
      // Leave API call to screen-level where meetingId is available. Here we just simulate success.
      final newRecord = FineRecord(
        id: DateTime.now().millisecondsSinceEpoch,
        memberId: memberId,
        type: type,
        date: date,
        paid: false,
        amount: type.amount,
      );
      records = [newRecord, ...records];
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAndRefresh({
    required int cycleId,
    required int meetingId,
    required int memberId,
    required FineType type,
    int? amount,
    String? reason,
  }) async {
    await _repo.assign(
      meetingId: meetingId,
      memberId: memberId,
      fineTypeKey: type.key,
      amount: amount,
      reason: reason,
    );
    await load(cycleId, meetingId);
  }
}
