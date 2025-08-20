import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class MeetingDto {
  final int id;
  final int cycleId;
  final String? name;
  final String? scheduledDate;
  final String? status; // scheduled|upcoming|in_progress|completed
  final String? currentStep;
  final String? closingNotes;
  final String? scheduledAt;
  final String? meetingDate;
  final bool? active;
  final bool? isOpen;

  MeetingDto({
    required this.id,
    required this.cycleId,
    required this.name,
    required this.scheduledDate,
    required this.status,
    required this.currentStep,
    required this.closingNotes,
    required this.scheduledAt,
    required this.meetingDate,
    required this.active,
    required this.isOpen,
  });

  factory MeetingDto.fromListJson(Map<String, dynamic> json) {
    return MeetingDto(
      id: json['id'] as int,
      cycleId: json['cycle_id'] as int? ?? 0,
      name: json['name'] as String?,
      scheduledDate: json['scheduled_date'] as String?,
      status: json['status'] as String?,
      currentStep: json['current_step'] as String?,
      closingNotes: json['closing_notes'] as String?,
      scheduledAt: json['scheduled_date'] as String?,
      meetingDate: json['meeting_date'] as String?,
      active: json['is_active'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? false,
    );
  }
}

class MeetingsApiRepository {
  MeetingsApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<List<MeetingDto>> list({
    required int cycleId,
    String? status,
    int? page,
    int? perPage,
  }) async {
    try {
      final res = await _dio.get(
        '/api/v1/cycles/$cycleId/meetings',
        queryParameters: {
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );
      final data =
          (res.data['data'] as List)
              .cast<Map<String, dynamic>>()
              .map(MeetingDto.fromListJson)
              .toList();
      return data;
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load meetings',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<MeetingDto> create({
    required int cycleId,
    required String scheduledDate,
    String? location,
    String? agenda,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/cycles/$cycleId/meetings',
        data: {
          'scheduled_date': scheduledDate,
          if (location != null) 'location': location,
          if (agenda != null) 'agenda': agenda,
        },
      );
      return MeetingDto.fromListJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create meeting',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> open({required int cycleId, required int meetingId}) async {
    try {
      await _dio.post('/api/v1/cycles/$cycleId/meetings/$meetingId/open');
    } on DioException catch (e) {
      throw ApiException(
        'Failed to open meeting',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateStep({
    required int cycleId,
    required int meetingId,
    required String currentStep,
  }) async {
    try {
      await _dio.post(
        '/api/v1/cycles/$cycleId/meetings/$meetingId/step',
        data: {'current_step': currentStep},
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to update step',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> close({
    required int cycleId,
    required int meetingId,
    String? minutes,
    String? closingNotes,
    bool? lock,
  }) async {
    try {
      await _dio.post(
        '/api/v1/cycles/$cycleId/meetings/$meetingId/close',
        data: {
          if (minutes != null) 'minutes': minutes,
          if (closingNotes != null) 'closing_notes': closingNotes,
          if (lock != null) 'lock': lock,
        },
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to close meeting',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
