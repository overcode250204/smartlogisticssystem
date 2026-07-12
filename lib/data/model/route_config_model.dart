import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';

enum DispatchType {
  TIME,
  CAPACITY,
  HYBRID;

  String get displayName {
    return switch (this) {
      DispatchType.TIME => 'Theo thời gian cố định',
      DispatchType.CAPACITY => 'Theo tải trọng tối thiểu',
      DispatchType.HYBRID => 'Kết hợp (Thời gian hoặc Tải trọng)',
    };
  }
}

class RouteConfigModel {
  final int routeId;
  final String routeName;
  final WarehouseModel fromWarehouse;
  final WarehouseModel toWarehouse;
  final DispatchType dispatchType;
  final VehicleModel? defaultVehicle;
  final String? fixedDispatchTime; // Format "HH:mm:ss" or "HH:mm"
  final int? minCapacityPercentage;
  final String cutoffTime; // Format "HH:mm:ss" or "HH:mm"
  final int? maxWaitingDays;
  final List<String> provinceNames;
  final bool isActive;
  final int? slaHours;

  const RouteConfigModel({
    required this.routeId,
    required this.routeName,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.dispatchType,
    this.defaultVehicle,
    this.fixedDispatchTime,
    this.minCapacityPercentage,
    required this.cutoffTime,
    this.maxWaitingDays,
    required this.provinceNames,
    required this.isActive,
    this.slaHours,
  });

  factory RouteConfigModel.fromJson(Map<String, dynamic> json) {
    return RouteConfigModel(
      routeId: json['routeId'] as int? ?? 0,
      routeName: json['routeName']?.toString() ?? '',
      fromWarehouse: WarehouseModel.fromJson(json['fromWarehouse'] ?? {}),
      toWarehouse: WarehouseModel.fromJson(json['toWarehouse'] ?? {}),
      dispatchType: DispatchType.values.firstWhere(
        (e) => e.name == json['dispatchType']?.toString(),
        orElse: () => DispatchType.TIME,
      ),
      defaultVehicle: json['defaultVehicle'] != null
          ? VehicleModel.fromJson(json['defaultVehicle'])
          : null,
      fixedDispatchTime: json['fixedDispatchTime']?.toString(),
      minCapacityPercentage: json['minCapacityPercentage'] as int?,
      cutoffTime: json['cutoffTime']?.toString() ?? '00:00',
      maxWaitingDays: json['maxWaitingDays'] as int?,
      provinceNames: List<String>.from(json['provinceNames'] ?? []),
      isActive: json['isActive'] as bool? ?? true,
      slaHours: json['slaHours'] as int?,
    );
  }
}

class RouteConfigCreateRequest {
  final String routeName;
  final int fromWarehouseId;
  final int toWarehouseId;
  final DispatchType dispatchType;
  final String? fixedDispatchTime;
  final int? minCapacityPercentage;
  final String cutoffTime;
  final int? maxWaitingDays;
  final int? defaultVehicleId;
  final List<String> provinceNames;
  final bool isActive;

  const RouteConfigCreateRequest({
    required this.routeName,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.dispatchType,
    this.fixedDispatchTime,
    this.minCapacityPercentage,
    required this.cutoffTime,
    this.maxWaitingDays,
    this.defaultVehicleId,
    required this.provinceNames,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'fromWarehouseId': fromWarehouseId,
      'toWarehouseId': toWarehouseId,
      'dispatchType': dispatchType.name,
      'fixedDispatchTime': fixedDispatchTime,
      'minCapacityPercentage': minCapacityPercentage,
      'cutoffTime': cutoffTime,
      'maxWaitingDays': maxWaitingDays,
      'defaultVehicleId': defaultVehicleId,
      'provinceNames': provinceNames,
      'isActive': isActive,
    };
  }
}

class RouteConfigUpdateRequest {
  final String routeName;
  final int fromWarehouseId;
  final int toWarehouseId;
  final DispatchType dispatchType;
  final String? fixedDispatchTime;
  final int? minCapacityPercentage;
  final String cutoffTime;
  final int? maxWaitingDays;
  final int? defaultVehicleId;
  final List<String> provinceNames;
  final bool isActive;

  const RouteConfigUpdateRequest({
    required this.routeName,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.dispatchType,
    this.fixedDispatchTime,
    this.minCapacityPercentage,
    required this.cutoffTime,
    this.maxWaitingDays,
    this.defaultVehicleId,
    required this.provinceNames,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'fromWarehouseId': fromWarehouseId,
      'toWarehouseId': toWarehouseId,
      'dispatchType': dispatchType.name,
      'fixedDispatchTime': fixedDispatchTime,
      'minCapacityPercentage': minCapacityPercentage,
      'cutoffTime': cutoffTime,
      'maxWaitingDays': maxWaitingDays,
      'defaultVehicleId': defaultVehicleId,
      'provinceNames': provinceNames,
      'isActive': isActive,
    };
  }
}
