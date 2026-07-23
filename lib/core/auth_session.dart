import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const int adminRoleId = 1;
  static const int managerRoleId = 2;
  static const int driverRoleId = 3;
  static const int staffRoleId = 4;

  const AuthSession._();

  static Future<int?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('roleId');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<int?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('driverId');
  }

  static Future<void> setDriverId(int driverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('driverId', driverId);
  }

  static Future<SessionUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final roleId = prefs.getInt('roleId');

    if (userId == null || roleId == null) return null;

    return SessionUser(
      userId: userId,
      roleId: roleId,
      fullName: prefs.getString('fullName')?.trim() ?? '',
      email: prefs.getString('email')?.trim() ?? '',
      roleName: prefs.getString('roleName')?.trim() ?? '',
    );
  }

  static Future<bool> isDriver() async {
    return await getRoleId() == driverRoleId;
  }

  static Future<bool> isStaff() async {
    return await getRoleId() == staffRoleId;
  }

  static Future<bool> canViewExportHistory() async {
    final roleId = await getRoleId();
    return roleId == adminRoleId || roleId == managerRoleId;
  }

  static String displayRole({required int roleId, String? roleName}) {
    final normalized = (roleName ?? '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .toUpperCase();

    if (roleId == adminRoleId || normalized == 'ADMIN') {
      return 'Quản trị viên';
    }
    if (roleId == managerRoleId ||
        normalized == 'WAREHOUSEMANAGER' ||
        normalized == 'WAREHOUSE_MANAGER') {
      return 'Quản lý kho';
    }
    if (roleId == staffRoleId || normalized == 'STAFF') {
      return 'Nhân viên';
    }
    if (roleId == driverRoleId || normalized == 'DRIVER') {
      return 'Tài xế';
    }

    return roleName?.trim().isNotEmpty == true
        ? roleName!.trim()
        : 'Người dùng';
  }
}

class SessionUser {
  final int userId;
  final int roleId;
  final String fullName;
  final String email;
  final String roleName;

  const SessionUser({
    required this.userId,
    required this.roleId,
    required this.fullName,
    required this.email,
    required this.roleName,
  });

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get displayRole =>
      AuthSession.displayRole(roleId: roleId, roleName: roleName);
}
