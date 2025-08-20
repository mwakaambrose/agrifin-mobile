import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../members/data/api/members_api_repository.dart';
import '../data/member_model.dart';
import '../data/member_repository.dart' as mock_repo;
import '../../../core/session/session_manager.dart';

class MemberProfileViewModel extends ChangeNotifier {
  final mock_repo.MemberRepository _repo;
  final MembersApiRepository _api;
  Member? _member;
  bool _loading = false;
  String? _error;

  MemberProfileViewModel({
    mock_repo.MemberRepository? repository,
    String? memberId,
  }) : _repo = repository ?? mock_repo.MemberRepository(),
       _api = MembersApiRepository() {
    if (memberId != null) {
      load(memberId);
    }
  }

  Member? get member => _member;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _member = await _repo.fetchMember(id);
    } catch (e) {
      _error = 'Failed to load member';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> changePhoneNumber(String newPhone) async {
    if (newPhone.isEmpty || newPhone.length < 10) return false;
    try {
      final ids = await _getIds();
      if (ids == null) return false;
      await _api.updateMember(
        group_id: ids.$1,
        memberId: ids.$2,
        data: {'phone': newPhone},
      );
      // Update local state optimistically
      if (_member != null) {
        _member = _member!.copyWith(phone: newPhone);
        await _repo.update(_member!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Change member PIN using authenticated API
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (newPin.isEmpty || newPin.length < 4) return false;
    try {
      final ids = await _getIds();
      if (ids == null) return false;
      await _api.changePin(
        group_id: ids.$1,
        memberId: ids.$2,
        currentPin: currentPin,
        newPin: newPin,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper to get group and member IDs from SessionManager or Hive
  Future<(int groupId, int memberId)?> _getIds() async {
    final sm = SessionManager.instance;
    int? groupId = sm.group_id;
    int? memberId = sm.memberId;
    if (groupId == null || memberId == null) {
      final box = await Hive.openBox('user_data');
      final g = box.get('group_id');
      final m = box.get('member_id');
      groupId = g is int ? g : int.tryParse(g?.toString() ?? '');
      memberId = m is int ? m : int.tryParse(m?.toString() ?? '');
    }
    if (groupId == null || memberId == null) return null;
    return (groupId, memberId);
  }
}
