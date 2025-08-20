import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class LoanScheduleItemDto {
  final int installment;
  final double principal;
  final double interest;
  final double total;
  final bool isPaid;

  LoanScheduleItemDto({
    required this.installment,
    required this.principal,
    required this.interest,
    required this.total,
    required this.isPaid,
  });

  factory LoanScheduleItemDto.fromJson(Map<String, dynamic> json) =>
      LoanScheduleItemDto(
        installment: (json['installment'] as num?)?.toInt() ?? 0,
        principal: (json['principal'] as num?)?.toDouble() ?? 0.0,
        interest: (json['interest'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        isPaid: json['is_paid'] as bool? ?? false,
      );
}

class LoanDto {
  final int id;
  final int cycleId;
  final int meetingId;
  final Map<String, dynamic>? member;
  final double amount;
  final double interestRate;
  final String interestType;
  final double totalInterestExpected;
  final double totalDue;
  final double totalPrincipalPaid;
  final double totalInterestPaid;
  final double remainingBalance;
  final String purpose;
  final int durationWeeks;
  final String startDate;
  final String dueDate;
  final String status;
  final List<LoanScheduleItemDto> schedule;
  final DateTime createdAt;

  LoanDto({
    required this.id,
    required this.cycleId,
    required this.meetingId,
    required this.member,
    required this.amount,
    required this.interestRate,
    required this.interestType,
    required this.totalInterestExpected,
    required this.totalDue,
    required this.totalPrincipalPaid,
    required this.totalInterestPaid,
    required this.remainingBalance,
    required this.purpose,
    required this.durationWeeks,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.schedule,
    required this.createdAt,
  });

  factory LoanDto.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] as String?;
    return LoanDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cycleId: (json['cycle_id'] as num?)?.toInt() ?? 0,
      meetingId: (json['meeting_id'] as num?)?.toInt() ?? 0,
      member: json['member'] as Map<String, dynamic>?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      interestType: (json['interest_type'] as String?) ?? '',
      totalInterestExpected:
          (json['total_interest_expected'] as num?)?.toDouble() ?? 0.0,
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
      totalPrincipalPaid:
          (json['total_principal_paid'] as num?)?.toDouble() ?? 0.0,
      totalInterestPaid:
          (json['total_interest_paid'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remaining_balance'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] as String? ?? '',
      durationWeeks: (json['duration_weeks'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      schedule:
          (json['schedule'] as List? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(LoanScheduleItemDto.fromJson)
              .toList(),
      createdAt:
          createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
    );
  }
}

class LoansListResponse {
  final double totalOutstandingBalance;
  final List<LoanDto> data;
  final Map<String, dynamic> meta;

  LoansListResponse({
    required this.totalOutstandingBalance,
    required this.data,
    required this.meta,
  });

  factory LoansListResponse.fromJson(Map<String, dynamic> json) =>
      LoansListResponse(
        totalOutstandingBalance:
            (json['total_outstanding_balance'] as num).toDouble(),
        data:
            (json['data'] as List)
                .cast<Map<String, dynamic>>()
                .map(LoanDto.fromJson)
                .toList(),
        meta: json['meta'] as Map<String, dynamic>,
      );
}

class LoansApiRepository {
  LoansApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<LoansListResponse> list(int cycleId) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$cycleId/loans');
      return LoansListResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load loans',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LoanDto> apply({
    required int meetingId,
    required int memberId,
    required double amount,
    int? durationWeeks,
    double? interestRate,
    String? interestType,
    String? purpose,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/meetings/$meetingId/loans/apply',
        data: {
          'member_id': memberId,
          'amount': amount,
          if (durationWeeks != null) 'duration_weeks': durationWeeks,
          if (interestRate != null) 'interest_rate': interestRate,
          if (interestType != null) 'interest_type': interestType,
          if (purpose != null) 'purpose': purpose,
        },
      );
      return LoanDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create loan',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> repay({
    required int meetingId,
    required int loanId,
    required double amount,
  }) async {
    try {
      await _dio.post(
        '/api/v1/meetings/$meetingId/loans/$loanId/repay',
        data: {'amount': amount},
      );
    } on DioException catch (e) {
      throw ApiException(
        'Failed to record repayment',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<LoanDto> show(int loanId) async {
    try {
      final res = await _dio.get('/api/v1/loans/$loanId');
      return LoanDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load loan',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
