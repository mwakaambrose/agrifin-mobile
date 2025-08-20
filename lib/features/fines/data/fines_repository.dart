import 'fines_models.dart';
import 'api/fines_api_repository.dart';
import '../../constitution/data/api/constitution_api_repository.dart';

class FinesRepository {
  FinesRepository({
    FinesApiRepository? api,
    ConstitutionApiRepository? constitutionApi,
  }) : _api = api ?? FinesApiRepository(),
       _constitutionApi = constitutionApi ?? ConstitutionApiRepository();
  final FinesApiRepository _api;
  final ConstitutionApiRepository _constitutionApi;

  Future<(List<FineType>, List<FineRecord>)> load({
    required int cycleId,
    required int meetingId,
  }) async {
    // Load fine types from constitution (late/absent/missed savings)
    final constitution = await _constitutionApi.getCurrent(cycleId);
    final List<FineType> types = [];
    int tempId = 1;
    if (constitution != null) {
      if (constitution.lateFine > 0) {
        types.add(
          FineType(
            id: tempId++,
            key: 'late',
            name: 'Late arrival',
            amount: constitution.lateFine.toInt(),
          ),
        );
      }
      if (constitution.absentFine > 0) {
        types.add(
          FineType(
            id: tempId++,
            key: 'absent',
            name: 'Absence',
            amount: constitution.absentFine.toInt(),
          ),
        );
      }
      if (constitution.missedSavingsFine > 0) {
        types.add(
          FineType(
            id: tempId++,
            key: 'missed_savings',
            name: 'Missed savings',
            amount: constitution.missedSavingsFine.toInt(),
          ),
        );
      }
    }
    // Optionally, if no types configured in constitution, fall back to API fine types
    if (types.isEmpty) {
      final typesDto = await _api.listFineTypes(cycleId: cycleId);
      types.addAll(
        typesDto.map(
          (t) => FineType(
            id: t.id,
            key: t.key,
            name: t.name,
            amount: t.defaultAmount.toInt(),
            adjustable: t.isAdjustable,
          ),
        ),
      );
    }

    final finesDto = await _api.listMeetingFines(meetingId);
    final records =
        finesDto
            .map(
              (r) => FineRecord(
                id: r.id,
                memberId: (r.member?['cycle_member_id'] as int?) ?? 0,
                type: _matchFineType(types, r.type, r.amount),
                date: r.createdAt,
                paid: r.isPaid,
                amount: r.amount.toInt(),
                reason: r.reason,
                paidAt: r.paidAt,
                transactionId: r.transactionId,
                member: r.member,
                meeting: r.meeting,
              ),
            )
            .toList();
    return (types, records);
  }

  FineType _matchFineType(List<FineType> types, String rawType, double amount) {
    final normalized = rawType.toLowerCase();
    FineType? match;
    // Try direct name match first
    match = types.firstWhere(
      (t) => t.name.toLowerCase() == normalized,
      orElse:
          () => types.firstWhere(
            (t) {
              final n = t.name.toLowerCase();
              if (normalized.contains('late')) return n.contains('late');
              if (normalized.contains('absent')) return n.contains('absenc');
              if (normalized.contains('miss') &&
                  normalized.contains('saving')) {
                return n.contains('miss') && n.contains('saving');
              }
              return false;
            },
            orElse:
                () => FineType(
                  id: -1,
                  key: rawType.toLowerCase().replaceAll(' ', '_'),
                  name: rawType,
                  amount: amount.toInt(),
                ),
          ),
    );
    return match;
  }

  Future<void> assign({
    required int meetingId,
    required int memberId,
    required String fineTypeKey,
    int? amount,
    String? reason,
  }) async {
    await _api.assignFine(
      meetingId: meetingId,
      memberId: memberId,
      fineTypeKey: fineTypeKey,
      amount: amount?.toDouble(),
      reason: reason,
    );
  }
}
