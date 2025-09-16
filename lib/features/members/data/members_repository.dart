import 'api/members_api_repository.dart';

class MemberLite {
  final int id;
  final String name;
  MemberLite({required this.id, required this.name});
}

class MembersRepository {
  MembersRepository({MembersApiRepository? api})
    : _api = api ?? MembersApiRepository();
  final MembersApiRepository _api;

  Future<List<MemberLite>> listByCycle(int groupId) async {
    final data = await _api.listCycleMembers(groupId);
    return data
        .map(
          (m) => MemberLite(
            id: (m['cycle_member_id'] as int?) ?? (m['id'] as int? ?? 0),
            name:
                (m['name'] as String?) ??
                (m['full_name'] as String? ?? 'Member ${m['id']}'),
          ),
        )
        .toList();
  }
}
