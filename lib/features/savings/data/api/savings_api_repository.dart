import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class SavingDto {
  final int id;
  final int amount;
  final int meetingId;
  final int cycleId;
  final int group_id;
  final Map<String, dynamic>? member;
  final Map<String, dynamic>? transaction;
  final String? notes;
  final DateTime createdAt;

  SavingDto({
    required this.id,
    required this.amount,
    required this.meetingId,
    required this.cycleId,
    required this.group_id,
    required this.member,
    required this.transaction,
    required this.notes,
    required this.createdAt,
  });

  factory SavingDto.fromJson(Map<String, dynamic> json) => SavingDto(
    id: json['id'] as int,
    amount: (json['amount'] as num).toInt(),
    meetingId: json['meeting_id'] as int,
    cycleId: json['cycle_id'] as int,
    group_id: json['group_id'] as int,
    member: json['member'] as Map<String, dynamic>?,
    transaction: json['transaction'] as Map<String, dynamic>?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class SavingsListResponse {
  final double totalSavingsBalance;
  final int group_id;
  final int? cycleId;
  final int? meetingId;
  final List<SavingDto> data;
  final Map<String, dynamic>? meta;

  SavingsListResponse({
    required this.totalSavingsBalance,
    required this.group_id,
    required this.cycleId,
    required this.meetingId,
    required this.data,
    required this.meta,
  });

  factory SavingsListResponse.fromJson(Map<String, dynamic> json) =>
      SavingsListResponse(
        totalSavingsBalance: (json['total_savings_balance'] as num).toDouble(),
        group_id: json['group_id'] as int,
        cycleId: json['cycle_id'] as int?,
        meetingId: json['meeting_id'] as int?,
        data:
            (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(SavingDto.fromJson)
                .toList(),
        meta: json['meta'] as Map<String, dynamic>?,
      );
}

class SavingsApiRepository {
  SavingsApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<SavingsListResponse> listAll({int? cycleId}) async {
    try {
      final res = await _dio.get(
        '/api/v1/savings',
        queryParameters: {if (cycleId != null) 'cycle_id': cycleId},
      );
      return SavingsListResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load savings',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SavingsListResponse> listForMeeting(int meetingId) async {
    try {
      final res = await _dio.get('/api/v1/meetings/$meetingId/savings');
      return SavingsListResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load meeting savings',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<SavingDto> recordSaving({
    required int meetingId,
    required int memberId,
    required int amount,
    int? shares,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/meetings/$meetingId/savings',
        data: {
          'member_id': memberId,
          'amount': amount,
          if (shares != null) 'shares': shares,
          if (notes != null) 'notes': notes,
        },
      );
      return SavingDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to record saving',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
