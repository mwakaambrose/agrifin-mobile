import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class ShareoutPayoutDto {
  final int cycleMemberId;
  final Map<String, dynamic>? member;
  final double totalSaved;
  final double savingsPercentage;
  final double profitShare;
  final double totalPayout;

  ShareoutPayoutDto({
    required this.cycleMemberId,
    required this.member,
    required this.totalSaved,
    required this.savingsPercentage,
    required this.profitShare,
    required this.totalPayout,
  });

  factory ShareoutPayoutDto.fromJson(Map<String, dynamic> json) =>
      ShareoutPayoutDto(
        cycleMemberId: json['cycle_member_id'] as int,
        member: json['member'] as Map<String, dynamic>?,
        totalSaved: (json['total_saved'] as num).toDouble(),
        savingsPercentage: (json['savings_percentage'] as num).toDouble(),
        profitShare: (json['profit_share'] as num).toDouble(),
        totalPayout: (json['total_payout'] as num).toDouble(),
      );
}

class ShareoutDto {
  final int cycleId;
  final double totalSavings;
  final double totalInterest;
  final double totalFines;
  final double totalProfit;
  final double sharePrice;
  final String? executedAt;
  final List<ShareoutPayoutDto> payouts;

  ShareoutDto({
    required this.cycleId,
    required this.totalSavings,
    required this.totalInterest,
    required this.totalFines,
    required this.totalProfit,
    required this.sharePrice,
    required this.executedAt,
    required this.payouts,
  });

  factory ShareoutDto.fromJson(Map<String, dynamic> json) => ShareoutDto(
    cycleId: json['cycle_id'] as int,
    totalSavings: (json['total_savings'] as num).toDouble(),
    totalInterest: (json['total_interest'] as num).toDouble(),
    totalFines: (json['total_fines'] as num).toDouble(),
    totalProfit: (json['total_profit'] as num).toDouble(),
    sharePrice: (json['share_price'] as num).toDouble(),
    executedAt: json['executed_at'] as String?,
    payouts:
        (json['payouts'] as List)
            .cast<Map<String, dynamic>>()
            .map(ShareoutPayoutDto.fromJson)
            .toList(),
  );
}

class ShareoutApiRepository {
  ShareoutApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<ShareoutDto> get(int cycleId) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$cycleId/shareout');
      return ShareoutDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load shareout',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<int> execute(int cycleId) async {
    try {
      final res = await _dio.post('/api/v1/cycles/$cycleId/shareout');
      return (res.data['shareout_id'] as num).toInt();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to execute shareout',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
