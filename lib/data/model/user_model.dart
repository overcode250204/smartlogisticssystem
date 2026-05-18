class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phone; 
  final String roleName;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.roleName,
    required this.isActive,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'], 
      roleName: json['roleName'] ?? 'Unknown',
      isActive: json['isActive'] ?? true,
    );
  }
}