import 'package:hive_flutter/hive_flutter.dart';
import 'network/dio_client.dart';

class ConfigRepository {
  static const String _boxName = 'config_box';
  static const String _key = 'config_json';

  Future<Map<String, dynamic>?> fetchRemote() async {
    final res = await DioClient().client.get('/api/mobile/config');
    final data = Map<String, dynamic>.from(res.data as Map);
    await cache(data);
    return data;
  }

  Future<void> cache(Map<String, dynamic> json) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, json);
  }

  Future<Map<String, dynamic>?> getCached() async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(_key);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
