import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/fail_point_request_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';

/// All driver-facing Local Trip endpoints (docs/local-trip-frontend-guide.md §4).
/// Every call carries a bespoke `driverId` header (distinct from the app-wide
/// X-Role-Id/X-User-Id headers), so it's set per-request rather than in the
/// shared ApiClient interceptor.
class LocalTripDriverService {
  final ApiClient _client = ApiClient();

  Options _driverHeader(int driverId) =>
      Options(headers: {'driverId': driverId});

  Future<List<LocalTripResponse>> getMyTrips(int driverId) async {
    final response = await _client.get(
      'driver/local-trips',
      options: _driverHeader(driverId),
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : body;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LocalTripResponse.fromJson)
        .toList();
  }

  Future<void> acceptTrip(int driverId, int tripId) async {
    await _client.put(
      'driver/local-trips/$tripId/accept',
      options: _driverHeader(driverId),
    );
  }

  Future<void> cancelTrip(int driverId, int tripId) async {
    await _client.put(
      'driver/local-trips/$tripId/cancel',
      options: _driverHeader(driverId),
    );
  }

  Future<void> scanBarcode(
    int driverId,
    int tripId,
    int orderId,
    String barcode,
  ) async {
    await _client.post(
      'driver/local-trips/$tripId/scan-barcode',
      queryParameters: {'orderId': orderId, 'barcode': barcode},
      options: _driverHeader(driverId),
    );
  }

  Future<void> startExecuting(int driverId, int tripId) async {
    await _client.put(
      'driver/local-trips/$tripId/start-executing',
      options: _driverHeader(driverId),
    );
  }

  Future<void> arrive(
    int driverId,
    int tripId,
    int detailId,
    double lat,
    double lon,
  ) async {
    await _client.put(
      'driver/local-trips/$tripId/details/$detailId/arrive',
      queryParameters: {'lat': lat, 'lon': lon},
      options: _driverHeader(driverId),
    );
  }

  Future<void> completePoint(
    int driverId,
    int tripId,
    int detailId,
    XFile proofImage,
  ) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'proofImage',
        await MultipartFile.fromFile(
          proofImage.path,
          filename: proofImage.path.split(Platform.pathSeparator).last,
        ),
      ),
    );
    await _client.put(
      'driver/local-trips/$tripId/details/$detailId/complete',
      data: formData,
      options: _driverHeader(driverId),
    );
  }

  Future<void> failPoint(
    int driverId,
    int tripId,
    int detailId,
    XFile proofImage,
    FailPointRequest data,
  ) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'proofImage',
        await MultipartFile.fromFile(
          proofImage.path,
          filename: proofImage.path.split(Platform.pathSeparator).last,
        ),
      ),
    );
    formData.files.add(
      MapEntry(
        'data',
        MultipartFile.fromString(
          jsonEncode(data.toJson()),
          contentType: DioMediaType.parse('application/json'),
        ),
      ),
    );
    await _client.put(
      'driver/local-trips/$tripId/details/$detailId/fail',
      data: formData,
      options: _driverHeader(driverId),
    );
  }
}
