class WarehouseResponse {
  final int warehouseId;
  final String name;
  final String? type;
  final String? address;
  final String? province;
  final double? latitude;
  final double? longitude;

  const WarehouseResponse({
    required this.warehouseId,
    required this.name,
    this.type,
    this.address,
    this.province,
    this.latitude,
    this.longitude,
  });

  factory WarehouseResponse.fromJson(Map<String, dynamic> json) {
    return WarehouseResponse(
      warehouseId: _parseInt(json['warehouseId']) ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      address: json['address']?.toString(),
      province: json['province']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
