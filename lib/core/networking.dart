// File: lib/core/networking.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

  // HÀM TỰ ĐỘNG CHỌN IP (MAGIC NẰM Ở ĐÂY)
  String _getDynamicBaseUrl() {
    // 1. Nếu chạy trên Web
    if (kIsWeb) {
      print('clientweb');
      return 'http://127.0.0.1:8080/api/';
    }

    // 2. Nếu chạy trên Máy tính (Windows, macOS, Linux)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      print('WindowMacOSLinux');
      return 'http://127.0.0.1:8080/api/';
    }

    // 3. Nếu chạy trên Điện thoại (Android, iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      print('clientAndroidIOS');
      // Dùng 10.0.2.2 cho Android Emulator để kết nối tới localhost của máy tính
      return 'http://10.0.2.2:8080/api/';
    }
    print('DefaultDevice');
    // Mặc định an toàn
    return 'http://10.0.2.2:8080/api/';
  }

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        // GỌI HÀM VỪA VIẾT VÀO ĐÂY
        baseUrl: _getDynamicBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // BỘ ĐÁNH CHẶN REQUEST (Kèm Token/ID)
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

          return handler.next(options);
        },
      ),
    );
  }

  // ... (Các hàm get, post, put, delete giữ nguyên không thay đổi)
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } catch (e) {
      rethrow;
    }
  }
}
