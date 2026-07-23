class DriverModel {
  final int? driverId;
  final String? name;
  final String? phone;
  final String? status;
  final String? driverType;

  DriverModel({
    this.driverId,
    this.name,
    this.phone,
    this.status,
    this.driverType,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: _toInt(json['driverId']),
      name: json['name'],
      phone: json['phone']?.toString(),
      status: json['status'],
      driverType: json['driverType'],
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
