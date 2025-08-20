import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class CycleSummaryReportDto {
  final Map<String, dynamic> cycle;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> profitAndLoss;
  final String generatedAt;

  CycleSummaryReportDto({
    required this.cycle,
    required this.metrics,
    required this.profitAndLoss,
    required this.generatedAt,
  });

  factory CycleSummaryReportDto.fromJson(Map<String, dynamic> json) =>
      CycleSummaryReportDto(
        cycle: json['cycle'] as Map<String, dynamic>,
        metrics: json['metrics'] as Map<String, dynamic>,
        profitAndLoss: json['profit_and_loss'] as Map<String, dynamic>,
        generatedAt: json['generated_at'] as String,
      );
}

class ReportsApiRepository {
  ReportsApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<CycleSummaryReportDto> cycleSummary(int cycleId) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$cycleId/reports/summary');
      return CycleSummaryReportDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load report',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
