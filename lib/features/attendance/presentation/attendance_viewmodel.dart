import 'package:flutter/foundation.dart';
import '../data/attendance_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel(this._repo);
  final AttendanceRepository _repo;

  bool loading = false;
  List<AttendanceRecordDto> records = [];
  String? error;

  Future<void> load(int meetingId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      records = await _repo.listForMeeting(meetingId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> mark({
    required int meetingId,
    required int memberId,
    required String status,
    DateTime? arrivalTime,
    String? reason,
  }) async {
    await _repo.upsert(
      meetingId: meetingId,
      memberId: memberId,
      status: status,
      arrivalTime: arrivalTime,
      reason: reason,
    );
    await load(meetingId);
  }
}
