import 'api/cycles_api_repository.dart';
import 'cycle_model.dart';

class CycleRepository {
  final CyclesApiRepository _api = CyclesApiRepository();

  Future<List<Cycle>> listCycles() async {
    try {
      final cycleDtos = await _api.list();
      return cycleDtos
          .map(
            (dto) => Cycle(
              id: dto.id,
              name: dto.name,
              startDate: DateTime.parse(dto.startDate),
              endDate: DateTime.parse(dto.endDate),
              isActive: dto.isCurrent,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cycles: $e');
    }
  }

  Future<Cycle> createCycle({
    required int groupId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    bool isCurrent = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Cycle(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isCurrent,
    );
  }

  Future<Cycle> updateCycle({
    required int id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? description,
    bool? isCurrent,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Cycle(
      id: id,
      name: name ?? 'Updated Cycle',
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      isActive: isCurrent ?? false,
    );
  }

  Future<void> closeCycle(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> deleteCycle(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
