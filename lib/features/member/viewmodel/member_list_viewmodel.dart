import 'package:agrifinity/features/common/viewmodels/base_viewmodel.dart';
import '../data/member_model.dart';
import '../data/member_repository.dart';

class MemberListViewModel extends BaseViewModel {
  final MemberRepository _repo;
  MemberListViewModel({MemberRepository? repository})
    : _repo = repository ?? MemberRepository();

  List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);

  Future<void> load() async {
    setBusy(true);
    setError(null);
    try {
      _members = await _repo.fetchMembers();
    } catch (e) {
      setError('Failed to load members');
    } finally {
      setBusy(false);
    }
  }

  Future<void> addMember(Member member) async {
    _members = [..._members, await _repo.add(member)];
    notifyListeners();
  }

  Future<void> updateMember(Member updated) async {
    final res = await _repo.update(updated);
    if (res != null) {
      _members = _members.map((m) => m.id == updated.id ? updated : m).toList();
      notifyListeners();
    }
  }

  Member? getMemberById(String id) =>
      _members.where((m) => m.id == id).firstOrNull;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
