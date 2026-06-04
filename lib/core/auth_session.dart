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
}
