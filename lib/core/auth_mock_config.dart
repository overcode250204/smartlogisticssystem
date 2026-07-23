import 'package:flutter/foundation.dart';

import 'package:smartlogisticssystem/core/auth_session.dart';

class AuthMockConfig {
  const AuthMockConfig._();

  static const bool phoneOtpEnabled = bool.fromEnvironment(
    'MOCK_PHONE_AUTH',
    defaultValue: kDebugMode,
  );

  static const String phoneOtpCode = String.fromEnvironment(
    'MOCK_PHONE_OTP',
    defaultValue: '123456',
  );

  static const String phoneRole = String.fromEnvironment(
    'MOCK_PHONE_ROLE',
    defaultValue: 'driver',
  );

  static const int driverUserId = int.fromEnvironment(
    'MOCK_DRIVER_USER_ID',
    defaultValue: 6,
  );

  static const int staffUserId = int.fromEnvironment(
    'MOCK_STAFF_USER_ID',
    defaultValue: 11,
  );

  static const String mockVerificationId = 'mock-phone-auth-verification-id';

  static bool get isStaff => phoneRole.toLowerCase() == 'staff';

  static int get roleId =>
      isStaff ? AuthSession.staffRoleId : AuthSession.driverRoleId;

  static int get userId => isStaff ? staffUserId : driverUserId;

  static String get roleName => isStaff ? 'STAFF' : 'DRIVER';

  static String get fullName =>
      isStaff ? 'Nhan vien Kho Mock' : 'Tai xe Linehaul Mock';

  static String get email =>
      isStaff ? 'staff_mock@test.com' : 'driver_mock@test.com';
}
