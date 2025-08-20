import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/exceptions.dart';

class FineTypeDto {
  final int id;
  final String key;
  final String name;
  final String? description;
  final double defaultAmount;
  final bool isAdjustable;

  FineTypeDto({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.defaultAmount,
    required this.isAdjustable,
  });

  factory FineTypeDto.fromJson(Map<String, dynamic> json) => FineTypeDto(
    id: json['id'] as int,
    key: json['key'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    defaultAmount: _toDouble(json['default_amount']),
    isAdjustable: json['is_adjustable'] as bool? ?? false,
  );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class FineRecordDto {
  final int id;
  final int cycleId;
  final int meetingId;
  final String type;
  final double amount;
  final String? reason;
  final bool isPaid;
  final DateTime? paidAt;
  final int? transactionId;
  final Map<String, dynamic>? member;
  final Map<String, dynamic>? meeting;
  final DateTime createdAt;
  final DateTime updatedAt;

  FineRecordDto({
    required this.id,
    required this.cycleId,
    required this.meetingId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.isPaid,
    required this.paidAt,
    required this.transactionId,
    required this.member,
    required this.meeting,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FineRecordDto.fromJson(Map<String, dynamic> json) => FineRecordDto(
    id: json['id'] as int,
    cycleId: json['cycle_id'] as int,
    meetingId: json['meeting_id'] as int,
    type: json['type'] as String,
    amount: FineTypeDto._toDouble(json['amount']),
    reason: json['reason'] as String?,
    isPaid: _toBool(json['is_paid']),
    paidAt:
        json['paid_at'] != null
            ? DateTime.tryParse(json['paid_at'] as String)
            : null,
    transactionId: json['transaction_id'] as int?,
    member: json['member'] as Map<String, dynamic>?,
    meeting: json['meeting'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

class FinesApiRepository {
  FinesApiRepository([Dio? dio]) : _dio = dio ?? DioClient().client;
  final Dio _dio;

  Future<List<FineTypeDto>> listFineTypes({required int cycleId}) async {
    try {
      final res = await _dio.get(
        '/api/v1/fine-types',
        queryParameters: {'cycle_id': cycleId},
      );
      return (res.data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(FineTypeDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load fine types',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<FineRecordDto>> listMeetingFines(int meetingId) async {
    try {
      final res = await _dio.get('/api/v1/meetings/$meetingId/fines');
      return (res.data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(FineRecordDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'Failed to load fines',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FineRecordDto> assignFine({
    required int meetingId,
    required int memberId,
    required String fineTypeKey,
    double? amount,
    String? reason,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/meetings/$meetingId/fines/assign',
        data: {
          'member_id': memberId,
          'fine_type_key': fineTypeKey,
          if (amount != null) 'amount': amount,
          if (reason != null) 'reason': reason,
        },
      );
      final data = (res.data['data'] as Map).cast<String, dynamic>();
      return FineRecordDto.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        'Failed to assign fine',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
