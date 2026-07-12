import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_model.dart';

enum LocalTripStatus {
PENDING_ACCEPTANCE,
ACCEPTED, 
CANCELLED,
ASSIGNED,
EXECUTING,
COMPLETED;

  String get displayName {
    return switch (this) {
      LocalTripStatus.PENDING_ACCEPTANCE => 'Đang chờ xác nhận',
      LocalTripStatus.ACCEPTED => 'Đã xác nhận',
      LocalTripStatus.CANCELLED => 'Đã hủy',
      LocalTripStatus.ASSIGNED => 'Đã giao',
      LocalTripStatus.EXECUTING => 'Đang thực hiện',
      LocalTripStatus.COMPLETED => 'Hoàn thành',
    };
  }
}

class LocalTripModel {
  final int? localTripId;
  final WarehouseModel? hub;
  final DriverModel? driver;
  final VehicleModel? vehicle;
  final LocalTripStatus? status;
  final DateTime? createdAt;
  final List<LocalTripDetailModel>? details;
  final String? localTripCode;
  final int? vrpEstimatedMinutes;

  LocalTripModel({
    this.localTripId,
    this.hub,
    this.driver,
    this.vehicle,
    this.status,
    this.createdAt,
    this.details,
    this.localTripCode,
    this.vrpEstimatedMinutes,
  });

  factory LocalTripModel.fromJson(Map<String, dynamic> json) {
    return LocalTripModel(
      localTripId: _toInt(json['localTripId']),
      hub: json['hub'] != null ? WarehouseModel.fromJson(json['hub']) : null,
      driver: json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
      vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
      status: json['status'] != null ? LocalTripStatus.values.firstWhere((e) => e.name == json['status']) : null,
      createdAt: _toDateTime(json['createdAt']),
      details: json['details'] != null
          ? (json['details'] as List).map((i) => LocalTripDetailModel.fromJson(i)).toList()
          : null,
      localTripCode: json['localTripCode'],
      vrpEstimatedMinutes: _toInt(json['vrpEstimatedMinutes']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

   static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value);
   }
}
