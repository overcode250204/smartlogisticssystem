enum WarehouseType {
  CDC,
  HUB;

  String get displayName {
    return switch (this) {
      WarehouseType.CDC => 'CDC (Trung tâm phân phối)',
      WarehouseType.HUB => 'HUB (Điểm trung chuyển)',
    };
  }
}

class WarehouseModel {
  final int warehouseId;
  final String name;
  final WarehouseType type;
  final String address;
  final String province;
  final double latitude;
  final double longitude;
  final String? startDeliveryTime;

  const WarehouseModel({
    required this.warehouseId,
    required this.name,
    required this.type,
    required this.address,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.startDeliveryTime,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      warehouseId: json['warehouseId'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      type: WarehouseType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => WarehouseType.CDC,
      ),
      address: json['address']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      startDeliveryTime: json['startDeliveryTime']?.toString(),
    );
  }
}

class WarehouseCreateRequest {
  final String name;
  final WarehouseType type;
  final String address;
  final String province;
  final double latitude;
  final double longitude;
  final String? startDeliveryTime;

  const WarehouseCreateRequest({
    required this.name,
    required this.type,
    required this.address,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.startDeliveryTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'address': address,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'startDeliveryTime': startDeliveryTime,
    };
  }
}

class WarehouseUpdateRequest {
  final String name;
  final WarehouseType type;
  final String address;
  final String province;
  final double latitude;
  final double longitude;
  final String? startDeliveryTime;

  const WarehouseUpdateRequest({
    required this.name,
    required this.type,
    required this.address,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.startDeliveryTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'address': address,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'startDeliveryTime': startDeliveryTime,
    };
  }
}
