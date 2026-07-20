class VehicleResponse {
  final int vehicleId;
  final String licensePlate;
  final String? vehicleType;
  final double? maxWeightKg;
  final double? maxVolumeM3;
  final String? status;

  const VehicleResponse({
    required this.vehicleId,
    required this.licensePlate,
    this.vehicleType,
    this.maxWeightKg,
    this.maxVolumeM3,
    this.status,
  });

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    return VehicleResponse(
      vehicleId: _parseInt(json['vehicleId']) ?? 0,
      licensePlate: json['licensePlate']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString(),
      maxWeightKg: _parseDouble(json['maxWeightKg']),
      maxVolumeM3: _parseDouble(json['maxVolumeM3']),
      status: json['status']?.toString(),
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
