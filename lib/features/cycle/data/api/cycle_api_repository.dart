import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class CurrentCycleDto {
  final int id;
  final String? name;
  CurrentCycleDto({required this.id, this.name});
  factory CurrentCycleDto.fromJson(Map<String, dynamic> json) =>
      CurrentCycleDto(id: json['id'] as int, name: json['name'] as String?);
}

class CycleApiRepository {
  CycleApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<CurrentCycleDto> fetchCurrent() async {
    try {
      final res = await _dio.get('/api/v1/cycles/current');
      // handle payloads as {data:{...}} or direct object
      final data =
          (res.data is Map<String, dynamic> &&
                  (res.data as Map<String, dynamic>)['data'] != null)
              ? (res.data as Map<String, dynamic>)['data']
                  as Map<String, dynamic>
              : res.data as Map<String, dynamic>;
      return CurrentCycleDto.fromJson(data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      String? body;
      if (data != null) {
        if (data is String) {
          body = data;
        } else {
          try {
            body = jsonEncode(data);
          } catch (_) {
            body = data.toString();
          }
        }
      }
      final msg =
          body == null
              ? 'Failed to fetch current cycle'
              : 'Failed to fetch current cycle (HTTP $code): $body';
      throw ApiException(msg, statusCode: code);
    }
  }
}
