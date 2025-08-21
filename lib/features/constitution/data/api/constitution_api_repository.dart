import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class ConstitutionDto {
  final int id;
  final int cycleId;
  final double savingsAmount;
  final double interestRate;
  final String interestType;
  final double welfareAmount;
  final int minGuarantors;
  final String meetingFrequency;
  final String meetingDay;
  final int meetingCount;
  final double lateFine;
  final double absentFine;
  final double missedSavingsFine;
  final String? additionalRules;
  final int version;
  final bool isActive;

  ConstitutionDto({
    required this.id,
    required this.cycleId,
    required this.savingsAmount,
    required this.interestRate,
    required this.interestType,
    required this.welfareAmount,
    required this.minGuarantors,
    required this.meetingFrequency,
    required this.meetingDay,
    required this.meetingCount,
    required this.lateFine,
    required this.absentFine,
    required this.missedSavingsFine,
    required this.additionalRules,
    required this.version,
    required this.isActive,
  });

  factory ConstitutionDto.fromJson(Map<String, dynamic> json) =>
      ConstitutionDto(
        id: _parseInt(json['id']),
        cycleId: _parseInt(json['cycle_id']),
        savingsAmount: _parseDouble(json['savings_amount']),
        interestRate: _parseDouble(json['interest_rate']),
        interestType: (json['interest_type'] ?? '').toString(),
        welfareAmount: _parseDouble(json['welfare_amount']),
        minGuarantors: _parseInt(json['min_guarantors']),
        meetingFrequency: (json['meeting_frequency'] ?? '').toString(),
        meetingDay: (json['meeting_day'] ?? '').toString(),
        meetingCount: _parseInt(json['meeting_count']),
        lateFine: _parseDouble(json['late_fine']),
        absentFine: _parseDouble(json['absent_fine']),
        missedSavingsFine: _parseDouble(json['missed_savings_fine']),
        additionalRules: _parseAdditionalRules(json['additional_rules']),
        version: _parseInt(json['version']),
        isActive: _parseBool(json['is_active'], defaultValue: true),
      );
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

bool _parseBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return defaultValue;
}

String? _parseAdditionalRules(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  // If API returns an array/object, store as JSON string
  try {
    return v.toString();
  } catch (_) {
    return null;
  }
}

class ConstitutionApiRepository {
  ConstitutionApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<ConstitutionDto?> getCurrent(int cycleId) async {
    try {
      final res = await _dio.get('/api/v1/cycles/$cycleId/constitution');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ConstitutionDto.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException(
        'Failed to load constitution',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ConstitutionDto> create(int cycleId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(
        '/api/v1/cycles/$cycleId/constitution',
        data: body,
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return ConstitutionDto.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to create constitution',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ConstitutionDto> update(
    int cycleId,
    int constitutionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.put(
        '/api/v1/cycles/$cycleId/constitution/$constitutionId',
        data: body,
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return ConstitutionDto.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to update constitution',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<ConstitutionDto>> history(int cycleId) async {
    try {
      final res = await _dio.get(
        '/api/v1/cycles/$cycleId/constitution/history',
      );
      final list = (res.data['data'] as List?) ?? const [];
      return list
          .map(
            (e) => ConstitutionDto.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load constitution history',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
