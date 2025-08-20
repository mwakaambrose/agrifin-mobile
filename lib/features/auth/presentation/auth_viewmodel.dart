import 'package:hive_flutter/hive_flutter.dart';

import '../../common/viewmodels/base_viewmodel.dart';
import '../data/auth_repository.dart';
import '../../../core/session/session_manager.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _repo;
  AuthViewModel(this._repo);

  bool _pinResetRequested = false;
  bool get pinResetRequested => _pinResetRequested;

  dynamic _user; // Add a field to store the logged-in user
  dynamic get user => _user; // Add a getter for the user field

  Future<bool> login(String phone, String pin) async {
    setBusy(true);
    setError(null);
    try {
      final result = await _repo.login(
        phone: phone,
        password: pin,
      ); // backend still expects password field
      _user = result.$2; // Store the logged-in user data
      // Persist user in session store
      // We don't have BuildContext here; use a global approach via a callback
      _onUserLoggedIn?.call(_user);
      // Mark session authenticated so GoRouter redirect logic allows /home immediately
      SessionManager.instance.setAuthenticated(true);

      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setBusy(false);
    }
  }

  // Callback set by the UI layer to persist user on login
  void Function(dynamic /*UserDto*/ user)? _onUserLoggedIn;
  void setOnUserLoggedIn(void Function(dynamic user) cb) {
    _onUserLoggedIn = (user) async {
      // Use SessionManager to store user data
      // Persist user data in Hive
      final box = await Hive.openBox('user_data');
      box.put('group_id', user.group_id); // Store group_id
      box.put('member_id', user.id); // Store member_id
      cb(user); // Call the original callback
      SessionManager.instance.setgroup_id(user.group_id); // Store group_id
      SessionManager.instance.setMemberId(user.id); // Store member_id
      cb(user); // Call the original callback
    };
  }

  Future<bool> requestPinReset(String phone) async {
    setBusy(true);
    setError(null);
    try {
      await _repo.requestPinReset(phone);
      _pinResetRequested = true;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setBusy(false);
    }
  }

  Future<bool> confirmPinReset(String phone, String code, String newPin) async {
    setBusy(true);
    setError(null);
    try {
      await _repo.confirmPinReset(phone: phone, code: code, newPin: newPin);
      _pinResetRequested = false;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setBusy(false);
    }
  }
}
