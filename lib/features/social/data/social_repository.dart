import 'social_models.dart';
import '../../welfare/data/api/welfare_api_repository.dart';

class SocialRepository {
  SocialRepository({WelfareApiRepository? api})
    : _api = api ?? WelfareApiRepository();
  final WelfareApiRepository _api;

  Future<(SocialBalance, List<SocialContribution>)> load(int cycleId) async {
    final res = await _api.listContributions(cycleId);
    final total = res.totalContributions.toInt();
    final list =
        res.data.map((d) {
          final m = d.member;
          String? name;
          if (m != null) {
            final n = m['name'] as String?;
            if (n != null && n.trim().isNotEmpty) {
              name = n.trim();
            } else {
              final parts =
                  [m['first_name'], m['last_name']]
                      .whereType<String>()
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
              if (parts.isNotEmpty) name = parts.join(' ').trim();
            }
          }
          return SocialContribution(
            id: d.id,
            meetingId: d.meetingId,
            memberId: (m?['id'] as num?)?.toInt() ?? 0,
            memberName: name,
            amount: d.amount.toInt(),
            date: d.createdAt,
          );
        }).toList();
    return (SocialBalance(cycleId: res.cycleId, balance: total), list);
  }

  Future<SocialContribution> addContribution({
    required int meetingId,
    required int memberId,
    required int amount,
    required DateTime date,
    String? notes,
  }) async {
    final dto = await _api.contribute(
      meetingId: meetingId,
      memberId: memberId,
      amount: amount.toDouble(),
      notes: notes,
      contributionDate: date,
    );
    final m = dto.member;
    String? name;
    if (m != null) {
      final n = m['name'] as String?;
      if (n != null && n.trim().isNotEmpty) {
        name = n.trim();
      } else {
        final parts =
            [
              m['first_name'],
              m['last_name'],
            ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) name = parts.join(' ').trim();
      }
    }
    return SocialContribution(
      id: dto.id,
      meetingId: dto.meetingId,
      memberId: (m?['id'] as num?)?.toInt() ?? 0,
      memberName: name,
      amount: dto.amount.toInt(),
      date: dto.createdAt,
    );
  }
}
