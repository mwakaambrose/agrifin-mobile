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

  void setAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }

  void setgroup_id(int? value) {
    if (_group_id != value) {
      _group_id = value;
      notifyListeners();
    }
  }

  void setMemberId(int? value) {
    if (_memberId != value) {
      _memberId = value;
      notifyListeners();
    }
  }
}
