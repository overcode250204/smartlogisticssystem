class UserModel {
  final int? userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String roleName;
  final bool isActive;
  final String? password;
  final String? identificationNumber;
  final String? address;
  final String? origin;
  final int? roleId;
  final String? driverType;
  final int? zoneId;
  final int? currentWarehouseId;
  final int? currentVehicleId;

  UserModel({
    this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.password,
    this.origin,
    this.address,
    required this.roleId,
    required this.roleName,
    required this.isActive,
    this.identificationNumber,
    this.driverType,
    this.zoneId,
    this.currentWarehouseId,
    this.currentVehicleId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: _toInt(json['userId']),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      roleName: json['roleName'] ?? 'Unknown',
      isActive: json['isActive'] ?? true,
      password: json['password'] ?? '',
      identificationNumber: json['identificationNumber']?.toString(),
      origin: json['origin'] ?? '',
      address: json['address'] ?? '',
      roleId: _toInt(json['roleId']),
      driverType: json['driverType'],
      zoneId: _toInt(json['zoneId']),
      currentWarehouseId: _toInt(json['currentWarehouseId']),
      currentVehicleId: _toInt(json['currentVehicleId']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'roleName': roleName,
      'isActive': isActive,
      'identificationNumber': identificationNumber,
      'origin': origin,
      'address': address,
      'roleId': roleId,
      'driverType': driverType,
      'zoneId': zoneId,
      'currentWarehouseId': currentWarehouseId,
      'currentVehicleId': currentVehicleId,
    };
  }
}
