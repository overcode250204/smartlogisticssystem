import 'driver_response_model.dart';
import 'local_trip_detail_response_model.dart';
import 'local_trip_status.dart';
import 'vehicle_response_model.dart';
import 'warehouse_response_model.dart';

class LocalTripResponse {
  final int localTripId;
  final String localTripCode;
  final WarehouseResponse? hub;
  final DriverResponse? driver;
  final VehicleResponse? vehicle;
  final LocalTripStatus status;
  final DateTime? createdAt;
  final int? vrpEstimatedMinutes;
  final List<LocalTripDetailResponse> details;

  const LocalTripResponse({
    required this.localTripId,
    required this.localTripCode,
    this.hub,
    this.driver,
    this.vehicle,
    required this.status,
    this.createdAt,
    this.vrpEstimatedMinutes,
    required this.details,
  });

  factory LocalTripResponse.fromJson(Map<String, dynamic> json) {
    return LocalTripResponse(
      localTripId: _parseInt(json['localTripId']) ?? 0,
      localTripCode: json['localTripCode']?.toString() ?? '',
      hub: json['hub'] != null
          ? WarehouseResponse.fromJson(json['hub'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? DriverResponse.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? VehicleResponse.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      status: LocalTripStatusX.fromApiValue(
        json['status']?.toString() ?? 'PENDING_ACCEPTANCE',
      ),
      createdAt: _parseDateTime(json['createdAt']),
      vrpEstimatedMinutes: _parseInt(json['vrpEstimatedMinutes']),
      details: json['details'] is List
          ? (json['details'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => LocalTripDetailResponse.fromJson(item))
              .toList()
          : const [],
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
