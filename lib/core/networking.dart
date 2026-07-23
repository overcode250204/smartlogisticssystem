// File: lib/core/networking.dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

  static String getBaseUrl() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return _normalizeBaseUrl(
        _configuredBaseUrl('MOBILE_BASE_URL') ?? 'http://10.0.2.2:8080/api/',
      );
    }

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return _normalizeBaseUrl(
        _configuredBaseUrl('BASE_URL') ?? 'http://127.0.0.1:8080/api/',
      );
    }

    return 'http://10.0.2.2:8080/api/';
  }

  static String? _configuredBaseUrl(String key) {
    try {
      final value = dotenv.env[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static String getWebSocketUrl() {
    final apiBaseUrl = getBaseUrl();
    final backendBaseUrl = apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final webSocketBaseUrl = backendBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    return '$webSocketBaseUrl/ws';
  }

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final roleId = prefs.getInt('roleId');
          final userId = prefs.getInt('userId');

          if (roleId != null) {
            options.headers['X-Role-Id'] = roleId;
          }

          if (userId != null) {
            options.headers['X-User-Id'] = userId;
          }

          handler.next(options);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              'API request failed: ${error.requestOptions.method} '
              '${error.requestOptions.uri} '
              'status=${error.response?.statusCode} '
              'message=${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final requestOptions = _withLongRunningTimeoutForAi(path, options);
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
    );
  }

  Options? _withLongRunningTimeoutForAi(String path, Options? options) {
    if (path != 'admin/ai-assistant/chat') {
      return options;
    }

    final mergedOptions = options ?? Options();
    mergedOptions.receiveTimeout = const Duration(seconds: 90);
    mergedOptions.sendTimeout = const Duration(seconds: 20);
    return mergedOptions;
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
