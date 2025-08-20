import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/home/data/dashboard_repository.dart';
import '../../features/meetings/data/meeting_status_service.dart';

class CurrentContext extends ChangeNotifier {
  int? _group_id;
  int? _cycleId;
  int? _activeMeetingId;

  int? get group_id => _group_id;
  int? get cycleId => _cycleId;
  int? get activeMeetingId => _activeMeetingId;

  bool get ready => _cycleId != null;

  Future<void> refresh() async {
    // 1) Prefer cached ids for instant availability
    try {
      final box = await Hive.openBox('user_data');
      final cachedGroup = box.get('group_id') as int?;
      final cachedCycle = box.get('cycle_id') as int?;
      if (cachedGroup != null || cachedCycle != null) {
        _group_id = cachedGroup ?? _group_id;
        _cycleId = cachedCycle ?? _cycleId;
        // Don't await meeting here; keep it snappy
        notifyListeners();
      }
    } catch (_) {
      // ignore cache errors; fall back to network
    }

    // 2) Fetch dashboard to ensure correctness
    final dash = await DashboardRepository().fetch();
    _group_id = dash.group_id;
    _cycleId = dash.cycleId;
    _activeMeetingId = await MeetingStatusService.getActiveMeeting();
    notifyListeners();
  }

  void setActiveMeeting(int? id) {
    _activeMeetingId = id;
    notifyListeners();
  }
}
