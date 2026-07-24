class DriverResponse {
  final int driverId;
  final String name;
  final String? phone;
  final String? status;
  final String? driverType;

  const DriverResponse({
    required this.driverId,
    required this.name,
    this.phone,
    this.status,
    this.driverType,
  });

  factory DriverResponse.fromJson(Map<String, dynamic> json) {
    return DriverResponse(
      driverId: _parseInt(json['driverId']) ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      status: json['status']?.toString(),
      driverType: json['driverType']?.toString(),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
