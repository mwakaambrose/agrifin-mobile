import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/meetings_models.dart';
import '../../data/meetings_repository.dart';
import '../../data/meeting_status_service.dart';

class MeetingsViewModel extends BaseViewModel {
  final MeetingsRepository _repo;
  MeetingsViewModel(this._repo);

  List<Meeting> meetings = [];
  int cycleId = 1; // set on load

  Future<void> load(int cycleId) async {
    setBusy(true);
    try {
      this.cycleId = cycleId;
      meetings = await _repo.list(cycleId);
      final activeId = await MeetingStatusService.getActiveMeeting();
      if (activeId != null) {
        meetings =
            meetings
                .map((m) => m.id == activeId ? m.copyWith(active: true) : m)
                .toList();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> startMeeting(int meetingId) async {
    final idx = meetings.indexWhere((m) => m.id == meetingId);
    if (idx == -1) return;
    // Call API to open meeting
    await _repo.startMeeting(cycleId: cycleId, meetingId: meetingId);
    meetings = [
      for (final m in meetings)
        m.id == meetingId
            ? m.copyWith(active: true)
            : m.copyWith(active: false),
    ];
    await MeetingStatusService.setActiveMeeting(meetingId);
    notifyListeners();
  }

  Future<void> endMeeting(int meetingId, {String? notes}) async {
    final idx = meetings.indexWhere((m) => m.id == meetingId);
    if (idx == -1) return;
    // Call API to close meeting
    await _repo.endMeeting(
      cycleId: cycleId,
      meetingId: meetingId,
      closingNotes: notes,
    );
    meetings[idx] = meetings[idx].copyWith(active: false, notes: notes);
    await MeetingStatusService.setActiveMeeting(null);
    notifyListeners();
  }

  Meeting? get activeMeeting =>
      meetings
                  .firstWhere(
                    (m) => m.active == true,
                    orElse:
                        () => Meeting(
                          id: -1,
                          cycleId: cycleId,
                          scheduledAt: DateTime.now().toIso8601String(),
                          active: false,
                        ),
                  )
                  .active ??
              false
          ? meetings.firstWhere((m) => m.active == true)
          : null;
}
