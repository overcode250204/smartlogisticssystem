enum VehicleType {
  BIKE,
  SMALL_TRUCK,
  BIG_TRUCK;

  String get displayName {
    return switch (this) {
      VehicleType.BIKE => 'Xe máy',
      VehicleType.SMALL_TRUCK => 'Xe tải nhỏ',
      VehicleType.BIG_TRUCK => 'Xe tải lớn',
    };
  }
}

enum VehicleStatus {
  ACTIVE,
  INACTIVE,
  MAINTENANCE,
  ON_TRIP;

  String get displayName {
    return switch (this) {
      VehicleStatus.ACTIVE => 'Hoạt động',
      VehicleStatus.INACTIVE => 'Không hoạt động',
      VehicleStatus.MAINTENANCE => 'Bảo trì',
      VehicleStatus.ON_TRIP => 'Đang giao hàng',
    };
  }
}

class VehicleModel {
  final int vehicleId;
  final String licensePlate;
  final VehicleType vehicleType;
  final double maxWeightKg;
  final double maxVolumeM3;
  final VehicleStatus status;
  final int? currentWarehouseId;
  final String? currentWarehouseName;

  const VehicleModel({
    required this.vehicleId,
    required this.licensePlate,
    required this.vehicleType,
    required this.maxWeightKg,
    required this.maxVolumeM3,
    required this.status,
    this.currentWarehouseId,
    this.currentWarehouseName,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicleId'] as int? ?? 0,
      licensePlate: json['licensePlate']?.toString() ?? '',
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == json['vehicleType']?.toString(),
        orElse: () => VehicleType.BIKE,
      ),
      maxWeightKg: (json['maxWeightKg'] as num?)?.toDouble() ?? 0.0,
      maxVolumeM3: (json['maxVolumeM3'] as num?)?.toDouble() ?? 0.0,
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => VehicleStatus.INACTIVE,
      ),
      currentWarehouseId: json['currentWarehouseId'] as int?,
      currentWarehouseName: json['currentWarehouseName']?.toString(),
    );
  }
}

class VehicleCreateRequest {
  final String licensePlate;
  final VehicleType vehicleType;
  final double maxWeightKg;
  final double maxVolumeM3;
  final VehicleStatus status;
  final int? currentWarehouseId;

  const VehicleCreateRequest({
    required this.licensePlate,
    required this.vehicleType,
    required this.maxWeightKg,
    required this.maxVolumeM3,
    required this.status,
    this.currentWarehouseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      'vehicleType': vehicleType.name,
      'maxWeightKg': maxWeightKg,
      'maxVolumeM3': maxVolumeM3,
      'status': status.name,
      'currentWarehouseId': currentWarehouseId,
    };
  }
}

class VehicleUpdateRequest {
  final String licensePlate;
  final VehicleType vehicleType;
  final double maxWeightKg;
  final double maxVolumeM3;
  final VehicleStatus status;
  final int? currentWarehouseId;

  const VehicleUpdateRequest({
    required this.licensePlate,
    required this.vehicleType,
    required this.maxWeightKg,
    required this.maxVolumeM3,
    required this.status,
    this.currentWarehouseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      'vehicleType': vehicleType.name,
      'maxWeightKg': maxWeightKg,
      'maxVolumeM3': maxVolumeM3,
      'status': status.name,
      'currentWarehouseId': currentWarehouseId,
    };
  }
}
