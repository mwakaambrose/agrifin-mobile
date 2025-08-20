import 'package:agrifinity/features/cycle/data/api/cycles_api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Cycle {
  final String id;
  String name;
  DateTime startDate;
  DateTime? endDate; // null if active
  int plannedMeetings; // target number of meetings for cycle
  int meetingsHeld;

  Cycle({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.plannedMeetings,
    required this.meetingsHeld,
  });

  bool get isActive => endDate == null;
  double get progress =>
      plannedMeetings == 0
          ? 0
          : (meetingsHeld / plannedMeetings).clamp(0, 1).toDouble();
}

class CycleViewModel extends ChangeNotifier {
  final List<CycleDto> _cycles = [
    CycleDto(
      id: 1,
      name: 'Cycle 3 (Current)',
      startDate:
          DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      group_id: 1,
      endDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      status: 'active',
      isCurrent: true,
    ),
    CycleDto(
      id: 2,
      name: 'Cycle 2',
      startDate:
          DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
      endDate:
          DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      group_id: 1,
      status: 'active',
      isCurrent: true,
    ),
    CycleDto(
      id: 3,
      name: 'Cycle 1',
      startDate:
          DateTime.now().subtract(const Duration(days: 540)).toIso8601String(),
      endDate:
          DateTime.now().subtract(const Duration(days: 400)).toIso8601String(),
      group_id: 1,
      status: 'active',
      isCurrent: true,
    ),
  ];

  bool _loading = false;
  String? _error;

  List<CycleDto> get cycles => List.unmodifiable(_cycles);
  bool get isLoading => _loading;
  String? get error => _error;
  CycleDto? get activeCycle {
    try {
      return _cycles.firstWhere((c) => c.isCurrent);
    } catch (_) {
      return null; // no active cycle
    }
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    // Placeholder for repository/API logic
    _loading = false;
    notifyListeners();
  }

  void closeActiveCycle() {
    final idx = _cycles.indexWhere((c) => c.isCurrent);
    if (idx == -1) return;
    final cycle = _cycles[idx];
    // _cycles[idx] = Cycle(
    //   id: cycle.id,
    //   name: cycle.name,
    //   startDate: cycle.startDate,
    //   endDate: DateTime.now(),
    //   plannedMeetings: cycle.plannedMeetings,
    //   meetingsHeld: cycle.meetingsHeld,
    // );

    notifyListeners();
  }

  void startNewCycle({required String name, required int plannedMeetings}) {
    // close existing active if any
    closeActiveCycle();
    // Api repository call to create a new cycle
    // dynamic box = await Hive.openBox("user_data");
    final newCycle = CycleDto(
      id: int.parse(DateTime.now().millisecondsSinceEpoch.toString()),
      name: name,
      startDate: DateTime.now().toIso8601String(),
      endDate: DateTime.now().toIso8601String(),
      group_id: 1,
      status: 'active',
      isCurrent: true,
    );
    // await _repository.createCycle(newCycle);
    notifyListeners();
  }
}
