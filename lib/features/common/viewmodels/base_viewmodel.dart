import 'package:flutter/foundation.dart';

class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  bool get busy => _busy;
  String? _error;
  String? get error => _error;

  void setBusy(bool value) {
    if (_busy != value) {
      _busy = value;
      notifyListeners();
    }
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
