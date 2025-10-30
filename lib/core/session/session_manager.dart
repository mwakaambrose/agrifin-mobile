import 'package:flutter/foundation.dart';

class SessionManager extends ChangeNotifier {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  int? _group_id;
  int? _memberId;

  int? get group_id => _group_id;
  int? get memberId => _memberId;

  // Prevent notification storms during auth state changes
  bool _isUpdating = false;

  void setAuthenticated(bool value) {
    if (_isAuthenticated != value && !_isUpdating) {
      _isUpdating = true;
      _isAuthenticated = value;
      // Defer notification to prevent immediate cascade
      Future.microtask(() {
        _isUpdating = false;
        notifyListeners();
      });
    }
  }

  void setgroup_id(int? value) {
    if (_group_id != value) {
      _group_id = value;
      // Don't notify for non-auth changes to prevent unnecessary rebuilds
    }
  }

  void setMemberId(int? value) {
    if (_memberId != value) {
      _memberId = value;
      // Don't notify for non-auth changes to prevent unnecessary rebuilds
    }
  }
}
