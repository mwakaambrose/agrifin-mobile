import 'meetings_models.dart';
import 'api/meetings_api_repository.dart';
import 'package:collection/collection.dart';

class MeetingsRepository {
  MeetingsRepository({MeetingsApiRepository? api})
    : _api = api ?? MeetingsApiRepository();
  final MeetingsApiRepository _api;

  Future<List<Meeting>> list(int cycleId, {String? status}) async {
    final items = await _api.list(cycleId: cycleId, status: status);
    return items
        .map(
          (m) => Meeting(
            id: m.id,
            cycleId: m.cycleId,
            scheduledAt: m.scheduledDate,
            name: m.name,
            meetingDate: m.meetingDate,
            status: m.status,
            active: m.active,
            isOpen: m.isOpen,
            currentStep: m.currentStep,
            closingNotes: m.closingNotes,
          ),
        )
        .toList();
  }

  Future<void> startMeeting({
    required int cycleId,
    required int meetingId,
  }) async {
    await _api.open(cycleId: cycleId, meetingId: meetingId);
  }

  Future<void> endMeeting({
    required int cycleId,
    required int meetingId,
    String? minutes,
    String? closingNotes,
    bool? lock,
  }) async {
    await _api.close(
      cycleId: cycleId,
      meetingId: meetingId,
      minutes: minutes,
      closingNotes: closingNotes,
      lock: lock,
    );
  }
}
