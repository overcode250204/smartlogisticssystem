import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';

enum PalletStatus {
  CREATING, CAN_SEAL, SEALED, IN_TRANSIT, ARRIVED;

  String get displayName {
    return switch (this) {
      PalletStatus.CREATING => 'Tạo pallet',
      PalletStatus.CAN_SEAL => 'Đợi dán seal',
      PalletStatus.SEALED => 'Đã dán seal',
      PalletStatus.IN_TRANSIT => 'Trên đường đi',
      PalletStatus.ARRIVED => 'Đã tới nơi',
    };
  }
}

class PalletModel {
  final int? palletId;
  final String? palletCode;
  final String? barcodeUrl;
  final RouteConfigModel? routeConfig;
  final LinehaulTripModel? linehaulTrip;
  final List<PalletItemModel>? palletItems;
  final String? status;
  final String? createdAt;
  final double? totalWeightKg;
  final double? totalVolumeM3;
  final bool? isCreatedSystem;

  PalletModel({
    this.palletId,
    this.palletCode,
    this.barcodeUrl,
    this.routeConfig,
    this.linehaulTrip,
    this.palletItems,
    this.status,
    this.createdAt,
    this.totalWeightKg,
    this.totalVolumeM3,
    this.isCreatedSystem,
  });

  factory PalletModel.fromJson(Map<String, dynamic> json) {
    return PalletModel(
      palletId: _toInt(json['palletId']),
      palletCode: json['palletCode'],
      barcodeUrl: json['barcodeUrl'],
      routeConfig: json['routeConfig'] != null ? RouteConfigModel.fromJson(json['routeConfig']) : null,
      linehaulTrip: json['linehaulTrip'] != null ? LinehaulTripModel.fromJson(json['linehaulTrip']) : null,
      palletItems: json['palletItems'] != null
          ? (json['palletItems'] as List).map((i) => PalletItemModel.fromJson(i)).toList()
          : null,
      status: json['status'],
      createdAt: json['createdAt'],
      totalWeightKg: _toDouble(json['totalWeightKg']),
      totalVolumeM3: _toDouble(json['totalVolumeM3']),
      isCreatedSystem: json['isCreatedSystem'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
