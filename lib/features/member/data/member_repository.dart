import 'member_model.dart';

class MemberRepository {
  // In-memory mock store
  final List<Member> _store = [
    Member(
      id: 1,
      name: 'Waiswa Steven',
      phone: '+256700000000',
      joinedOn: DateTime.now().subtract(const Duration(days: 600)),
      roles: const ['Group Leader'],
      savings: 550000,
      loans: 45000,
      socialFund: 120000,
    ),
    Member(
      id: 2,
      name: 'Jane Doe',
      phone: '+256701234567',
      joinedOn: DateTime.now().subtract(const Duration(days: 300)),
      roles: const ['Treasurer'],
      savings: 320000,
      loans: 0,
      socialFund: 80000,
    ),
  ];

  Future<List<Member>> fetchMembers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_store);
  }

  Future<Member?> fetchMember(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _store.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Member> add(Member member) async {
    _store.add(member);
    return member;
  }

  Future<Member?> update(Member member) async {
    final idx = _store.indexWhere((m) => m.id == member.id);
    if (idx == -1) return null;
    _store[idx] = member;
    return member;
  }
}
