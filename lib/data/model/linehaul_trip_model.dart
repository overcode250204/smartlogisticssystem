import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';

enum LinehaulTripStatus {
  PREPARING,
  CAN_START,
  EN_ROUTE,
  ARRIVED,
  CANCELLED;

  String get displayName {
    return switch (this) {
      LinehaulTripStatus.PREPARING => 'Chuẩn bị',
      LinehaulTripStatus.EN_ROUTE => 'Trên đường đi',
      LinehaulTripStatus.ARRIVED => 'Đã tới nơi',
      LinehaulTripStatus.CANCELLED => 'Hủy',
      LinehaulTripStatus.CAN_START => 'Đợi xe và tài xế',
    };
  }
}

class LinehaulTripModel {
  final int? linehaulId;
  final RouteConfigModel? routeConfig;
  final List<LinehaulTripDriverModel>? linehaulTripDriver;
  final List<PalletModel>? pallets;
  final VehicleModel? vehicle;
  final LinehaulTripStatus? status;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? linehaultripCode;

  LinehaulTripModel({
    this.linehaulId,
    this.routeConfig,
    this.linehaulTripDriver,
    this.pallets,
    this.vehicle,
    this.status,
    this.departureTime,
    this.arrivalTime,
    this.linehaultripCode,
  });

  factory LinehaulTripModel.fromJson(Map<String, dynamic> json) {
    return LinehaulTripModel(
      linehaulId: _toInt(json['linehaulId']),
      routeConfig: json['routeConfig'] != null ? RouteConfigModel.fromJson(json['routeConfig']) : null,
      linehaulTripDriver: json['linehaulTripDriver'] != null
          ? (json['linehaulTripDriver'] as List).map((i) => LinehaulTripDriverModel.fromJson(i)).toList()
          : null,
      pallets: json['pallets'] != null
          ? (json['pallets'] as List).map((i) => PalletModel.fromJson(i)).toList()
          : null,
      vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
      status: json['status'] != null ? LinehaulTripStatus.values.firstWhere((e) => e.name == json['status']) : null,
      departureTime: _toDateTime(json['departureTime']),
      arrivalTime: _toDateTime(json['arrivalTime']),
      linehaultripCode: json['linehaulTripCode'],
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
