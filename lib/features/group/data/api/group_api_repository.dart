import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class GroupProfileDto {
  final Map<String, dynamic> data;
  GroupProfileDto(this.data);
  factory GroupProfileDto.fromJson(Map<String, dynamic> json) =>
      GroupProfileDto(json['data'] as Map<String, dynamic>);
}

class GroupApiRepository {
  GroupApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<GroupProfileDto> getProfile(int group_id) async {
    try {
      final res = await _dio.get('/api/v1/groups/$group_id/profile');
      return GroupProfileDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load group profile',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
