import 'dart:collection';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../network/dio_client.dart';

class QueuedRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  QueuedRequest({required this.method, required this.path, this.data});

  Map<String, dynamic> toJson() => {
    'method': method,
    'path': path,
    'data': data,
  };

  static QueuedRequest fromJson(Map<String, dynamic> json) => QueuedRequest(
    method: json['method'] as String,
    path: json['path'] as String,
    data: (json['data'] as Map?)?.cast<String, dynamic>(),
  );
}

class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _boxName = 'offline_queue';
  final Queue<QueuedRequest> _queue = Queue();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final box = await Hive.openBox(_boxName);
    final list = (box.get('items') as List?)?.cast<String>() ?? [];
    for (final s in list) {
      _queue.add(QueuedRequest.fromJson(jsonDecode(s) as Map<String, dynamic>));
    }
    _initialized = true;
  }

  Future<void> add(QueuedRequest req) async {
    await init();
    _queue.add(req);
    await _persist();
  }

  Future<void> flush() async {
    await init();
    final dio = DioClient().client;
    while (_queue.isNotEmpty) {
      final req = _queue.first;
      try {
        switch (req.method.toUpperCase()) {
          case 'POST':
            await dio.post(req.path, data: req.data);
            break;
          case 'PUT':
            await dio.put(req.path, data: req.data);
            break;
          case 'PATCH':
            await dio.patch(req.path, data: req.data);
            break;
          case 'DELETE':
            await dio.delete(req.path, data: req.data);
            break;
        }
        _queue.removeFirst();
        await _persist();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> _persist() async {
    final box = await Hive.openBox(_boxName);
    final list = _queue.map((e) => jsonEncode(e.toJson())).toList();
    await box.put('items', list);
  }
}
