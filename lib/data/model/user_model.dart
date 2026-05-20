class UserModel {
  final int? userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String roleName;
  final bool isActive;
  final String? password;
  final int? identificationNumber;
  final String? address;
  final String? origin;
  final int? roleId;

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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int?,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      roleName: json['roleName'] ?? 'Unknown',
      isActive: json['isActive'] ?? true,
      password: json['password'] ?? '',
      identificationNumber: json['identificationNumber'] as int?,
      origin: json['origin'] ?? '',
      address: json['address'] ?? '',
      roleId: json['roleId'] as int,
    );
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
    };
  }
}
