import 'package:agrifinity/features/cycle/data/api/cycles_api_repository.dart';

import '../../../common/viewmodels/base_viewmodel.dart';
import '../../data/cycle_model.dart';

class CycleViewModel extends BaseViewModel {
  final CyclesApiRepository _repo;
  CycleViewModel(this._repo);

  List<CycleDto> cycles = [];

  Future<void> load() async {
    setBusy(true);
    try {
      cycles = await _repo.list();
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> createCycle({
    required int groupId,
    required String name,
    required dynamic startDate,
    required dynamic endDate,
    String? description,
    bool isCurrent = false,
  }) async {
    setBusy(true);
    try {
      final newCycle = await _repo.createCycle(
        groupId: groupId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        isCurrent: isCurrent,
      );
      cycles.add(newCycle);
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> updateCycle({
    required int cycleId,
    String? name,
    dynamic startDate,
    dynamic endDate,
    String? status,
    String? description,
    bool? isCurrent,
  }) async {
    setBusy(true);
    try {
      final updatedCycle = await _repo.update(cycleId, {
        if (name != null) 'name': name,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (isCurrent != null) 'is_current': isCurrent,
      });
      final index = cycles.indexWhere((c) => c.id == cycleId);
      if (index != -1) {
        cycles[index] = updatedCycle;
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> closeCycle(int cycleId) async {
    setBusy(true);
    try {
      await _repo.closeCycle(cycleId);
      final index = cycles.indexWhere((c) => c.id == cycleId);
      if (index != -1) {
        cycles[index] = cycles[index].copyWith(status: 'completed');
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> deleteCycle(int cycleId) async {
    setBusy(true);
    try {
      await _repo.deleteCycle(cycleId);
      cycles.removeWhere((c) => c.id == cycleId);
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }
}
