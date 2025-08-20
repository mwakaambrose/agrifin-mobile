import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class TransactionDto {
  final int id;
  final int? meetingId;
  final Map<String, dynamic>? meeting;
  final int? accountId;
  final Map<String, dynamic>? account;
  final int? memberId;
  final Map<String, dynamic>? member;
  final String type;
  final double amount;
  final double? balanceAfter;
  final String? description;
  final int? referenceId;
  final DateTime createdAt;

  TransactionDto({
    required this.id,
    required this.meetingId,
    required this.meeting,
    required this.accountId,
    required this.account,
    required this.memberId,
    required this.member,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.referenceId,
    required this.createdAt,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'] as int,
    meetingId: json['meeting_id'] as int?,
    meeting: json['meeting'] as Map<String, dynamic>?,
    accountId: json['account_id'] as int?,
    account: json['account'] as Map<String, dynamic>?,
    memberId: json['member_id'] as int?,
    member: json['member'] as Map<String, dynamic>?,
    type: json['type'] as String,
    amount: (json['amount'] as num).toDouble(),
    balanceAfter: (json['balance_after'] as num?)?.toDouble(),
    description: json['description'] as String?,
    referenceId: json['reference_id'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class TransactionsListResponse {
  final List<TransactionDto> data;
  final Map<String, dynamic> meta;

  TransactionsListResponse({required this.data, required this.meta});

  factory TransactionsListResponse.fromJson(Map<String, dynamic> json) =>
      TransactionsListResponse(
        data:
            (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(TransactionDto.fromJson)
                .toList(),
        meta: json['meta'] as Map<String, dynamic>,
      );
}

class TransactionsApiRepository {
  TransactionsApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<TransactionsListResponse> list({
    required int cycleId,
    String? type,
    int? memberId,
    int? accountId,
    int? meetingId,
    String? fromDate,
    String? toDate,
    String? search,
    int? page,
    int? perPage,
  }) async {
    int attempts = 0;
    DioException? lastError;
    while (attempts < 2) {
      try {
        final res = await _dio.get(
          '/api/v1/cycles/$cycleId/transactions',
          queryParameters: {
            if (type != null) 'type': type,
            if (memberId != null) 'member_id': memberId,
            if (accountId != null) 'account_id': accountId,
            if (meetingId != null) 'meeting_id': meetingId,
            if (fromDate != null) 'from_date': fromDate,
            if (toDate != null) 'to_date': toDate,
            if (search != null) 'search': search,
            if (page != null) 'page': page,
            if (perPage != null) 'per_page': perPage,
          },
        );
        return TransactionsListResponse.fromJson(
          res.data as Map<String, dynamic>,
        );
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 429) {
          // brief backoff to respect rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          continue;
        }
        break;
      }
    }
    final code = lastError?.response?.statusCode;
    if (code == 429) {
      throw ApiException(
        'Rate limit exceeded. Please try again shortly.',
        statusCode: code,
      );
    }
    throw ApiException('Failed to load transactions', statusCode: code);
  }
}
