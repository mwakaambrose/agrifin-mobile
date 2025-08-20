import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class CycleDto {
  final int id;
  final int group_id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final bool isCurrent;

  CycleDto({
    required this.id,
    required this.group_id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isCurrent,
  });

  factory CycleDto.fromJson(Map<String, dynamic> json) => CycleDto(
    id: json['id'] as int,
    group_id: json['group_id'] as int? ?? 0,
    name: json['name'] as String,
    startDate: json['start_date'] as String? ?? '',
    endDate: json['end_date'] as String? ?? '',
    status: json['status'] as String,
    isCurrent: json['is_current'] as bool? ?? false,
  );

  // add a copyWith function
  CycleDto copyWith({
    int? id,
    int? group_id,
    String? name,
    String? startDate,
    String? endDate,
    String? status,
    bool? isCurrent,
  }) {
    return CycleDto(
      id: id ?? this.id,
      group_id: group_id ?? this.group_id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

class CyclesApiRepository {
  CyclesApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<List<CycleDto>> list({
    int? group_id,
    String? status,
    bool? isCurrent,
    int? page,
    int? perPage,
  }) async {
    try {
      final res = await _dio.get(
        '/api/v1/cycles',
        queryParameters: {
          if (group_id != null) 'group_id': group_id,
          if (status != null) 'status': status,
          if (isCurrent != null) 'is_current': isCurrent,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return (res.data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(CycleDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load cycles',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CycleDto> create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/api/v1/cycles', data: body);
      return CycleDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CycleDto> show(int id) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$id');
      return CycleDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CycleDto> update(int id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put('/api/v1/cycles/$id', data: body);
      return CycleDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to update cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> close(int id) async {
    try {
      await _dio.post('/api/v1/cycles/$id/close');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to close cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/v1/cycles/$id');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to delete cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CycleDto> createCycle({
    required int groupId,
    required String name,
    required String startDate,
    required String endDate,
    String? description,
    bool isCurrent = false,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/cycles',
        data: {
          'group_id': groupId,
          'name': name,
          'start_date': startDate,
          'end_date': endDate,
          'description': description,
          'is_current': isCurrent,
        },
      );
      return CycleDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<CycleDto> updateCycle({
    required int cycleId,
    String? name,
    String? startDate,
    String? endDate,
    String? status,
    String? description,
    bool? isCurrent,
  }) async {
    try {
      final res = await _dio.put(
        '/api/v1/cycles/$cycleId',
        data: {
          if (name != null) 'name': name,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (status != null) 'status': status,
          if (description != null) 'description': description,
          if (isCurrent != null) 'is_current': isCurrent,
        },
      );
      return CycleDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to update cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> closeCycle(int cycleId) async {
    try {
      await _dio.post('/api/v1/cycles/$cycleId/close');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to close cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteCycle(int cycleId) async {
    try {
      await _dio.delete('/api/v1/cycles/$cycleId');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to delete cycle',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
