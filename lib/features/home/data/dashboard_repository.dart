import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/exceptions.dart';

class DashboardSummary {
  final int group_id;
  final int cycleId;
  final String cycleName;
  final double? cycleProgressPercent;
  final int meetingsScheduled;
  final int meetingsCompleted;
  final int membersTotal;
  final double attendanceRatePercent;
  final double totalSavings;
  final double totalOutstandingLoan;

  DashboardSummary({
    required this.group_id,
    required this.cycleId,
    required this.cycleName,
    required this.cycleProgressPercent,
    required this.meetingsScheduled,
    required this.meetingsCompleted,
    required this.membersTotal,
    required this.attendanceRatePercent,
    required this.totalSavings,
    required this.totalOutstandingLoan,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final meetings = (json['meetings'] as Map<String, dynamic>? ?? {});
    return DashboardSummary(
      group_id: (json['group_id'] ?? 0) as int,
      cycleId: (json['cycle_id'] ?? 0) as int,
      cycleName: (json['cycle_name'] ?? '') as String,
      cycleProgressPercent:
          (json['cycle_progress_percent'] as num?)?.toDouble(),
      meetingsScheduled: (meetings['scheduled'] ?? 0) as int,
      meetingsCompleted: (meetings['completed'] ?? 0) as int,
      membersTotal: (json['members_total'] ?? 0) as int,
      attendanceRatePercent:
          (json['attendance_rate_percent'] as num? ?? 0).toDouble(),
      totalSavings: (json['total_savings'] as num? ?? 0).toDouble(),
      totalOutstandingLoan:
          (json['total_outstanding_loan'] as num? ?? 0).toDouble(),
    );
  }
}

class DashboardRepository {
  DashboardRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<DashboardSummary> fetch() async {
    try {
      final res = await _dio.get('/api/v1/dashboard');
      return DashboardSummary.fromJson((res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load dashboard',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
