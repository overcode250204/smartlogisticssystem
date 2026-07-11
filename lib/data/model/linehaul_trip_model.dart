import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';

class LinehaulTripModel {
  final int? linehaulId;
  final RouteConfigModel? routeConfig;
  final List<LinehaulTripDriverModel>? linehaulTripDriver;
  final List<PalletModel>? pallets;
  final VehicleModel? vehicle;
  final String? status;
  final String? departureTime;
  final String? arrivalTime;

  LinehaulTripModel({
    this.linehaulId,
    this.routeConfig,
    this.linehaulTripDriver,
    this.pallets,
    this.vehicle,
    this.status,
    this.departureTime,
    this.arrivalTime,
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
      status: json['status'],
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
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
