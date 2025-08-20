import 'package:agrifinity/features/common/viewmodels/base_viewmodel.dart';
import 'package:agrifinity/features/home/data/dashboard_repository.dart';

class HomeViewModel extends BaseViewModel {
  DashboardSummary? _summary;
  DashboardSummary? get summary => _summary;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  double get cycleProgressValue {
    final s = _summary;
    if (s == null) return 0;
    // Prefer meetings-based ratio for visual consistency with the  X/Y label
    if (s.meetingsScheduled > 0) {
      final ratio = s.meetingsCompleted / s.meetingsScheduled;
      return ratio.clamp(0, 1);
    }
    // Fallback to server-provided percent; handle both 0..1 and 0..100 inputs
    if (s.cycleProgressPercent != null) {
      final p = s.cycleProgressPercent!;
      if (p <= 1) return p.clamp(0, 1);
      return (p.clamp(0, 100)) / 100.0;
    }
    return 0;
  }

  String get cycleProgressLabel {
    final s = _summary;
    if (s == null) return '-/-';
    return '${s.meetingsCompleted}/${s.meetingsScheduled}';
  }

  String get attendancePercentLabel {
    final s = _summary;
    if (s == null) return '—';
    return '${s.attendanceRatePercent.toStringAsFixed(0)}%';
  }

  Future<void> load() async {
    setBusy(true);
    setError(null);
    try {
      _summary = await DashboardRepository().fetch();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }
}
