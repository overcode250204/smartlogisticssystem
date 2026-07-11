import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_model.dart';

class LocalTripModel {
  final int? localTripId;
  final WarehouseModel? hub;
  final DriverModel? driver;
  final VehicleModel? vehicle;
  final String? status;
  final String? createdAt;
  final List<LocalTripDetailModel>? details;

  LocalTripModel({
    this.localTripId,
    this.hub,
    this.driver,
    this.vehicle,
    this.status,
    this.createdAt,
    this.details,
  });

  factory LocalTripModel.fromJson(Map<String, dynamic> json) {
    return LocalTripModel(
      localTripId: _toInt(json['localTripId']),
      hub: json['hub'] != null ? WarehouseModel.fromJson(json['hub']) : null,
      driver: json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
      vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
      status: json['status'],
      createdAt: json['createdAt'],
      details: json['details'] != null
          ? (json['details'] as List).map((i) => LocalTripDetailModel.fromJson(i)).toList()
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
