import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:go_router/go_router.dart';
import '../config.dart';
import '../navigation/navigation_service.dart';
import '../offline/offline_queue.dart';
import '../session/session_manager.dart';

class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;

  final _storage = const FlutterSecureStorage();
  Dio? _dio;
  bool _redirectingToLogin = false;
  DateTime? _lastErrorToastAt;

  Dio get client {
    _dio ??= _createDio();
    return _dio!;
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;
          final isMemberLogin =
              path.endsWith('/members/login') ||
              path.contains('/api/v1/members/login');
          if (!isMemberLogin) {
            final token = await _storage.read(key: 'auth_token');
            if (token != null && token.isNotEmpty) {
              options.headers[AppConfig.authHeader] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (res, handler) async {
          // Try to flush queued writes after any successful response
          try {
            await OfflineQueueService.instance.flush();
          } catch (_) {}
          return handler.next(res);
        },
        onError: (e, handler) async {
          // Queue write requests on connectivity errors
          final method = e.requestOptions.method.toUpperCase();
          final isWrite =
              method == 'POST' ||
              method == 'PUT' ||
              method == 'PATCH' ||
              method == 'DELETE';
          final isNetworkIssue =
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown ||
              e.type == DioExceptionType.connectionTimeout;

          // Don't queue logout requests - they should fail immediately
          final isLogout = e.requestOptions.path.contains('/logout');

          if (isWrite && isNetworkIssue && !isLogout) {
            try {
              await OfflineQueueService.instance.add(
                QueuedRequest(
                  method: method,
                  path: e.requestOptions.path,
                  data:
                      e.requestOptions.data is Map
                          ? (e.requestOptions.data as Map)
                              .cast<String, dynamic>()
                          : null,
                ),
              );
            } catch (_) {}
          }

          if (e.response?.statusCode == 401 && !_redirectingToLogin) {
            _redirectingToLogin = true;
            try {
              await _storage.delete(key: 'auth_token');
            } catch (_) {}
            // Mark unauthenticated so global redirect rules take effect
            SessionManager.instance.setAuthenticated(false);
            final ctx = NavigationService.rootNavigatorKey.currentContext;
            if (ctx != null) {
              try {
                ctx.go('/login');
              } catch (_) {}
            }
            _redirectingToLogin = false;
          }
          // Show error toast for API errors (exclude auth redirect)
          try {
            final code = e.response?.statusCode;
            if (code != 401) {
              String message = 'Request failed';
              final data = e.response?.data;
              if (data is Map && data['message'] is String) {
                message = data['message'] as String;
              } else if (data is String && data.trim().isNotEmpty) {
                message = data.trim();
              } else if (code != null) {
                message = 'Request failed (HTTP $code)';
              }
              final now = DateTime.now();
              if (_lastErrorToastAt == null ||
                  now.difference(_lastErrorToastAt!).inMilliseconds > 800) {
                final ctx = NavigationService.rootNavigatorKey.currentContext;
                if (ctx != null) {
                  final messenger = ScaffoldMessenger.maybeOf(ctx);
                  messenger?.hideCurrentSnackBar();
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(message),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _lastErrorToastAt = now;
                }
              }
            }
          } catch (_) {}
          return handler.next(e);
        },
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: (obj) {},
        retries: 3,
        retryDelays: const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 2),
        ],
        retryEvaluator: (error, attempt) {
          return error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown ||
              (error.response?.statusCode ?? 0) >= 500;
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: false,
        responseHeader: false,
        compact: true,
      ),
    );

    return dio;
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
