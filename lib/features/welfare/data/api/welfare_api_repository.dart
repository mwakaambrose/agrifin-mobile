import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class WelfareContributionDto {
  final int id;
  final int meetingId;
  final Map<String, dynamic>? member;
  final double amount;
  final dynamic notes;
  final Map<String, dynamic>? transaction;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WelfareContributionDto({
    required this.id,
    required this.meetingId,
    required this.member,
    required this.amount,
    required this.notes,
    required this.transaction,
    required this.createdAt,
    this.updatedAt,
  });

  factory WelfareContributionDto.fromJson(Map<String, dynamic> json) =>
      WelfareContributionDto(
        id: (json['id'] as num? ?? 0).toInt(),
        meetingId: (json['meeting_id'] as num? ?? 0).toInt(),
        member: json['member'] as Map<String, dynamic>?,
        amount: (json['amount'] as num? ?? 0.0).toDouble(),
        notes: json['notes'],
        transaction: json['transaction'] as Map<String, dynamic>?,
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : DateTime.now(),
        updatedAt:
            json['updated_at'] != null
                ? DateTime.parse(json['updated_at'] as String)
                : null,
      );
}

class WelfareListResponse {
  final double totalContributions;
  final int cycleId;
  final List<WelfareContributionDto> data;
  final Map<String, dynamic> meta;
  final Map<String, dynamic>? links;

  WelfareListResponse({
    required this.totalContributions,
    required this.cycleId,
    required this.data,
    required this.meta,
    this.links,
  });

  factory WelfareListResponse.fromJson(Map<String, dynamic> json) =>
      WelfareListResponse(
        totalContributions:
            (json['total_contributions'] as num? ?? 0.0).toDouble(),
        cycleId: (json['cycle_id'] as num? ?? 0).toInt(),
        data:
            (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(WelfareContributionDto.fromJson)
                .toList(),
        meta: json['meta'] as Map<String, dynamic>,
        links: json['links'] as Map<String, dynamic>?,
      );
}

class WelfareApiRepository {
  WelfareApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<WelfareListResponse> listContributions(int cycleId) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$cycleId/welfare');
      return WelfareListResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load welfare',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<WelfareContributionDto> contribute({
    required int meetingId,
    required int memberId,
    required double amount,
    String? notes,
    DateTime? contributionDate,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/meetings/$meetingId/welfare/contribute',
        data: {
          'member_id': memberId,
          'amount': amount,
          if (notes != null) 'notes': notes,
          if (contributionDate != null)
            'contribution_date': contributionDate.toIso8601String().substring(
              0,
              10,
            ),
        },
      );
      final data = res.data as Map<String, dynamic>;
      return WelfareContributionDto.fromJson(
        data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to contribute to welfare',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> disburse({
    required int meetingId,
    required int recipientId,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    try {
      await _dio.post(
        '/api/v1/meetings/$meetingId/welfare/disburse',
        data: {
          'recipient_id': recipientId,
          'amount': amount,
          'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to disburse welfare',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
