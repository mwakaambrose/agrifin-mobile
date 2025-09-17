import 'savings_models.dart';
import 'api/savings_api_repository.dart';

class SavingsRepository {
  SavingsRepository({SavingsApiRepository? api})
    : _api = api ?? SavingsApiRepository();
  final SavingsApiRepository _api;

  Future<SavingsAccountSummary> getSummary(int cycleId) async {
    // Not provided directly by API; can be derived from transactions endpoint in future.
    // For now, return a placeholder with 0 to avoid blocking the UI.
    return SavingsAccountSummary(balance: 0, cycleId: cycleId);
  }

  Future<List<SavingsTransaction>> getTransactions({
    required int cycleId,
  }) async {
    // This can be backed by /api/v1/cycles/{cycle}/transactions?type=saving
    // Implement later; return empty list for now.
    return [];
  }

  Future<void> contributeToMeeting({
    required int meetingId,
    required int memberId,
    required int amount,
    int? shares,
    String? note,
  }) async {
    await _api.recordSaving(
      meetingId: meetingId,
      memberId: memberId,
      amount: amount,
      shares: shares,
      notes: note,
    );
  }

  Future<SavingsData> getForMeeting(int meetingId) async {
    final res = await _api.listForMeeting(meetingId);
    final summary = SavingsAccountSummary(
      balance: res.totalSavingsBalance.toInt(),
      cycleId: res.cycleId ?? 0,
    );
    final txs =
        res.data.map((dto) {
          final m = dto.member;
          final memberId = (m != null) ? (m['id'] as num?)?.toInt() ?? 0 : 0;
          String? memberName;
          if (m != null) {
            final n = m['name'] as String?;
            if (n != null && n.trim().isNotEmpty) {
              memberName = n.trim();
            } else {
              final parts =
                  [m['first_name'], m['last_name']]
                      .whereType<String>()
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
              if (parts.isNotEmpty) memberName = parts.join(' ').trim();
            }
          }
          return SavingsTransaction(
            id: dto.id,
            memberId: memberId,
            date: dto.createdAt,
            amount: dto.amount,
            note: dto.notes,
            memberName: memberName,
          );
        }).toList();
    return SavingsData(summary: summary, transactions: txs);
  }

  Future<SavingsData> getAll({int? cycleId}) async {
    final res = await _api.listAll(cycleId: cycleId);
    final summary = SavingsAccountSummary(
      balance: res.totalSavingsBalance.toInt(),
      cycleId: res.cycleId != null ? int.parse(res.cycleId) : 0,
    );
    final txs =
        res.data.map((dto) {
          final m = dto.member;
          final memberId = (m != null) ? (m['id'] as num?)?.toInt() ?? 0 : 0;
          String? memberName;
          if (m != null) {
            final n = m['name'] as String?;
            if (n != null && n.trim().isNotEmpty) {
              memberName = n.trim();
            } else {
              final parts =
                  [m['first_name'], m['last_name']]
                      .whereType<String>()
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
              if (parts.isNotEmpty) memberName = parts.join(' ').trim();
            }
          }
          return SavingsTransaction(
            id: dto.id,
            memberId: memberId,
            date: dto.createdAt,
            amount: dto.amount,
            note: dto.notes,
            memberName: memberName,
          );
        }).toList();
    return SavingsData(summary: summary, transactions: txs);
  }
}
