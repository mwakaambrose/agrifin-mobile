import 'package:hive/hive.dart';

class MeetingStatusService {
  static const String _boxName = 'meetingStatusBox';
  static const String _activeMeetingKey = 'activeMeeting';

  static Future<void> setActiveMeeting(int? meetingId) async {
    final box = await Hive.openBox(_boxName);
    if (meetingId != null) {
      await box.put(_activeMeetingKey, meetingId);
    } else {
      await box.delete(_activeMeetingKey);
    }
  }

  static Future<int?> getActiveMeeting() async {
    final box = await Hive.openBox(_boxName);
    return box.get(_activeMeetingKey) as int?;
  }
}
