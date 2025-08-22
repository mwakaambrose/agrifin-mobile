import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class MemberAuthDto {
  final String token;
  final Map<String, dynamic> member;
  MemberAuthDto({required this.token, required this.member});
  factory MemberAuthDto.fromJson(Map<String, dynamic> json) => MemberAuthDto(
    token: json['token'] as String,
    member: json['member'] as Map<String, dynamic>,
  );
}

class MembersApiRepository {
  MembersApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<MemberAuthDto> login({
    required String phone,
    required String pin,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/members/login',
        data: {'phone': phone, 'pin': pin},
      );
      return MemberAuthDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Invalid credentials',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/members/logout');
    } on DioException catch (_) {}
  }

  Future<void> changePin({
    required int group_id,
    required int memberId,
    required String currentPin,
    required String newPin,
  }) async {
    try {
      await _dio.put(
        '/api/v1/groups/$group_id/members/$memberId/pin',
        data: {'current_pin': currentPin, 'new_pin': newPin},
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to change PIN',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> requestPinReset(String phone) async {
    try {
      await _dio.post(
        '/api/v1/members/pin/request-reset',
        data: {'phone': phone},
      );
    } on DioException catch (_) {}
  }

  Future<void> confirmPinReset({
    required String phone,
    required String code,
    required String newPin,
  }) async {
    try {
      await _dio.post(
        '/api/v1/members/pin/confirm-reset',
        data: {'phone': phone, 'code': code, 'new_pin': newPin},
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to reset PIN',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<Map<String, dynamic>>> listCycleMembers(dynamic group_id) async {
    try {
      final res = await _dio.get('/api/v1/groups/$group_id/members');
      return (res.data['data'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load members',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> createMember({
    required dynamic groupId,
    required String name,
    String? phone,
    String? email,
    String? nationalId,
    String? address,
    String? region,
    String? district,
    String? gender,
    String? maritalStatus,
    bool? hasDisability,
    String? idType,
    String? idNumber,
    String? photoPath, // local file path for profile picture
    required String pin,
    required String joinedAt, // Added joinedAt parameter
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'region': region,
        'district': district,
        // keep legacy national_id while also sending id_type/number
        if ((nationalId ?? idNumber) != null &&
            (idType == null || idType == 'national_id'))
          'national_id': nationalId ?? idNumber,
        'gender': gender,
        'marital_status': maritalStatus,
        'has_disability': hasDisability,
        'id_type': idType,
        'id_number': idNumber ?? nationalId,
        'pin': pin,
        'joined_at': joinedAt,
      };

      if (photoPath != null && photoPath.isNotEmpty) {
        final form = FormData.fromMap({
          ...payload,
          'photo': await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split('/').last,
          ),
        });
        await _dio.post('/api/v1/groups/$groupId/members', data: form);
      } else {
        await _dio.post('/api/v1/groups/$groupId/members', data: payload);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        final message = errorData['message'] ?? 'Validation error occurred.';
        final errors = errorData['errors'] ?? {};
        throw ApiException(
          '$message\n${errors.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join('\n')}',
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        'Failed to create member',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getMemberDetails({
    required int group_id,
    required int memberId,
  }) async {
    try {
      final res = await _dio.get('/api/v1/groups/$group_id/members/$memberId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        'Failed to fetch member details',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getLoggedInUser({
    required int group_id,
    required int memberId,
  }) async {
    try {
      final res = await _dio.get('/api/v1/groups/$group_id/members/$memberId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException(
        'Failed to fetch logged-in user data',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateMember({
    required int group_id,
    required int memberId,
    required Map<String, dynamic> data,
    String? photoPath, // optional local file path for profile picture
  }) async {
    try {
      final Map<String, dynamic> payload = {
        ...data,
        // ensure legacy mapping if applicable
        if (data['id_type'] == 'national_id' && data['id_number'] != null)
          'national_id': data['id_number'],
      };

      if (photoPath != null && photoPath.isNotEmpty) {
        final form = FormData.fromMap({
          ...payload,
          'photo': await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split('/').last,
          ),
        });
        await _dio.put(
          '/api/v1/groups/$group_id/members/$memberId',
          data: form,
        );
      } else {
        await _dio.put(
          '/api/v1/groups/$group_id/members/$memberId',
          data: payload,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        final message = errorData['message'] ?? 'Validation error occurred.';
        final errors = errorData['errors'] ?? {};
        throw ApiException(
          '$message\n${errors.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join('\n')}',
          statusCode: e.response?.statusCode,
        );
      }
      throw ApiException(
        'Failed to update member',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> disableMember({
    required int group_id,
    required int memberId,
  }) async {
    try {
      await _dio.put('/api/v1/groups/$group_id/members/$memberId/disable');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to disable member',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteMember({
    required int group_id,
    required int memberId,
  }) async {
    try {
      await _dio.delete('/api/v1/groups/$group_id/members/$memberId');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to delete member',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> activateMember({
    required int group_id,
    required int memberId,
  }) async {
    try {
      await _dio.post('/api/v1/groups/$group_id/members/$memberId/activate');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to activate member',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
