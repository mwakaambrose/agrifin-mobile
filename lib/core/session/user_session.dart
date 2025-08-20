import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user.dart';

class UserSession extends ChangeNotifier {
  static const String _box = 'user_box';
  static const String _key = 'current_user';

  UserDto? _user;
  UserDto? get user => _user;
  String get name => _user?.name ?? '';

  Future<void> loadFromCache() async {
    final box = await Hive.openBox(_box);
    final data = box.get(_key);
    if (data is Map) {
      try {
        _user = UserDto.fromJson(Map<String, dynamic>.from(data));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> setUser(UserDto user) async {
    _user = user;
    final box = await Hive.openBox(_box);
    await box.put(_key, user.toJson());
    notifyListeners();
  }

  Future<void> clear() async {
    _user = null;
    final box = await Hive.openBox(_box);
    await box.delete(_key);
    notifyListeners();
  }
}
