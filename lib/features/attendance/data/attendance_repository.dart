import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/exceptions.dart';

class AttendanceRecordDto {
  final int id;
  final int meetingId;
  final int cycleMemberId;
  final String status; // present | late | absent
  final DateTime? arrivalTime;
  final String? reason;

  AttendanceRecordDto({
    required this.id,
    required this.meetingId,
    required this.cycleMemberId,
    required this.status,
    this.arrivalTime,
    this.reason,
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordDto(
      id: json['id'] as int,
      meetingId: json['meeting_id'] as int,
      cycleMemberId: json['cycle_member_id'] as int,
      status: json['status'] as String,
      arrivalTime:
          json['arrival_time'] != null
              ? DateTime.tryParse(json['arrival_time'] as String)
              : null,
      reason: json['reason'] as String?,
    );
  }
}

class AttendanceRepository {
  AttendanceRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<List<AttendanceRecordDto>> listForMeeting(int meetingId) async {
    try {
      final res = await _dio.get('/api/v1/meetings/$meetingId/attendance');
      final list =
          (res.data['data'] as List)
              .cast<Map<String, dynamic>>()
              .map(AttendanceRecordDto.fromJson)
              .toList();
      return list;
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load attendance',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AttendanceRecordDto> upsert({
    required int meetingId,
    required int memberId,
    required String status,
    DateTime? arrivalTime,
    String? reason,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/meetings/$meetingId/attendance/$memberId',
        data: {
          'status': status,
          if (arrivalTime != null)
            'arrival_time': arrivalTime.toUtc().toIso8601String(),
          if (reason != null) 'reason': reason,
        },
      );
      return AttendanceRecordDto.fromJson(
        (res.data['attendance'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to mark attendance',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AttendanceRecordDto> update({
    required int meetingId,
    required int attendanceId,
    String? status,
    DateTime? arrivalTime,
    String? reason,
  }) async {
    try {
      final res = await _dio.put(
        '/api/v1/meetings/$meetingId/attendance/$attendanceId',
        data: {
          if (status != null) 'status': status,
          if (arrivalTime != null)
            'arrival_time': arrivalTime.toUtc().toIso8601String(),
          if (reason != null) 'reason': reason,
        },
      );
      return AttendanceRecordDto.fromJson(
        (res.data['attendance'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to update attendance',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
