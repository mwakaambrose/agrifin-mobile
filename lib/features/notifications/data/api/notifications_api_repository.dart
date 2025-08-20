import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class NotificationDto {
  final int id;
  final int group_id;
  final String title;
  final String? body;
  final String level;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime createdAt;

  NotificationDto({
    required this.id,
    required this.group_id,
    required this.title,
    required this.body,
    required this.level,
    required this.data,
    required this.readAt,
    required this.dismissedAt,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as int,
        group_id: json['group_id'] as int,
        title: json['title'] as String,
        body: json['body'] as String?,
        level: json['level'] as String,
        data: json['data'] as Map<String, dynamic>?,
        readAt:
            json['read_at'] != null
                ? DateTime.tryParse(json['read_at'] as String)
                : null,
        dismissedAt:
            json['dismissed_at'] != null
                ? DateTime.tryParse(json['dismissed_at'] as String)
                : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class NotificationsListResponse {
  final List<NotificationDto> data;
  final Map<String, dynamic> meta;

  NotificationsListResponse({required this.data, required this.meta});

  factory NotificationsListResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsListResponse(
        data:
            (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(NotificationDto.fromJson)
                .toList(),
        meta: json['meta'] as Map<String, dynamic>,
      );
}

class NotificationsApiRepository {
  NotificationsApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<NotificationsListResponse> list({
    required int group_id,
    String? status,
    int? page,
    int? perPage,
  }) async {
    try {
      final res = await _dio.get(
        '/api/v1/groups/$group_id/notifications',
        queryParameters: {
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      return NotificationsListResponse.fromJson(
        res.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load notifications',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<NotificationDto> create({
    required int group_id,
    required String title,
    String? body,
    String? level,
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/groups/$group_id/notifications',
        data: {
          'title': title,
          if (body != null) 'body': body,
          if (level != null) 'level': level,
          if (data != null) 'data': data,
        },
      );
      return NotificationDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create notification',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<NotificationDto> markRead({
    required int group_id,
    required int notificationId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/groups/$group_id/notifications/$notificationId/read',
      );
      return NotificationDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to mark notification read',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<NotificationDto> dismiss({
    required int group_id,
    required int notificationId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/groups/$group_id/notifications/$notificationId/dismiss',
      );
      return NotificationDto.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to dismiss notification',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
