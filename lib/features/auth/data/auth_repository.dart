import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/exceptions.dart';
import '../../../core/session/session_manager.dart';
import 'models/user.dart';

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class AuthRepository {
  AuthRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<(String token, UserDto user)> login({
    required String phone,
    required String password,
  }) async {
    try {
      var cleanedPhone = phone.replaceAll('+', '');
      final res = await _dio.post(
        '/api/v1/members/login',
        data: {'phone': cleanedPhone, 'pin': password},
      );
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserDto.fromJson(
        (data['member'] ?? data['user']) as Map<String, dynamic>,
      );
      final cycleId = data['cycle_id'] as int;
      final groupId = data['group_id'] as int;

      final box = await Hive.openBox('user_data');
      await box.put('group_id', groupId);
      await box.put('cycle_id', cycleId);

      await _storage.write(key: 'auth_token', value: token);
      await DioClient().setToken(token);
      return (token, user);
    } on DioException catch (e) {
      String msg = 'Login failed';
      if (e.response?.data is Map<String, dynamic>) {
        final body = e.response!.data as Map<String, dynamic>;
        msg = body['message'] as String? ?? msg;
        final errors = body['errors'];
        if (errors is Map) {
          final first = (errors.values.cast<List?>().firstOrNull ?? const [])
              .cast()
              .map((e) => e.toString())
              .join(', ');
          if (first.isNotEmpty) msg = first;
        }
      }
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/members/logout');
    } catch (_) {}
    await DioClient().clearToken();
    // Remove stored token to clear session completely
    await _storage.delete(key: 'auth_token');
    // Update session state (centralized)
    SessionManager.instance.setAuthenticated(false);
  }

  Future<UserDto> me() async {
    try {
      final res = await _dio.get('/api/v1/members/me');
      return UserDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to fetch profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> requestPinReset(String phone) async {
    // Placeholder: integrate with backend endpoint e.g. /api/mobile/auth/pin/request
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> confirmPinReset({
    required String phone,
    required String code,
    required String newPin,
  }) async {
    // Placeholder: integrate with backend endpoint e.g. /api/mobile/auth/pin/confirm
    await Future.delayed(const Duration(milliseconds: 600));
  }
}
