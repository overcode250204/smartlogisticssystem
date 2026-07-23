import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/core/networking.dart';

void main() {
  group('AuthSession', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null current user when required ids are missing', () async {
      expect(await AuthSession.getCurrentUser(), isNull);
    });

    test('hydrates and trims current user from shared preferences', () async {
      SharedPreferences.setMockInitialValues({
        'userId': 42,
        'roleId': AuthSession.managerRoleId,
        'fullName': '  Linh Nguyen  ',
        'email': '  linh@example.com  ',
        'roleName': ' WAREHOUSE_MANAGER ',
      });

      final user = await AuthSession.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.userId, 42);
      expect(user.roleId, AuthSession.managerRoleId);
      expect(user.fullName, 'Linh Nguyen');
      expect(user.email, 'linh@example.com');
      expect(user.displayName, 'Linh Nguyen');
      expect(user.displayRole, AuthSession.displayRole(roleId: 2));
    });

    test('checks role based permissions', () async {
      SharedPreferences.setMockInitialValues({
        'roleId': AuthSession.driverRoleId,
      });
      expect(await AuthSession.isDriver(), isTrue);
      expect(await AuthSession.isStaff(), isFalse);
      expect(await AuthSession.canViewExportHistory(), isFalse);

      SharedPreferences.setMockInitialValues({
        'roleId': AuthSession.adminRoleId,
      });
      expect(await AuthSession.canViewExportHistory(), isTrue);
    });

    test('displayRole handles ids, normalized role names, and fallback', () {
      expect(AuthSession.displayRole(roleId: 1), isNotEmpty);
      expect(
        AuthSession.displayRole(roleId: 99, roleName: ' staff '),
        isNotEmpty,
      );
      expect(
        AuthSession.displayRole(roleId: 99, roleName: 'Custom Role'),
        'Custom Role',
      );
      expect(AuthSession.displayRole(roleId: 99), isNotEmpty);
    });
  });

  group('ApiClient URL helpers', () {
    test('builds websocket URL from the configured API base URL', () {
      expect(ApiClient.getBaseUrl(), endsWith('/api/'));
      expect(ApiClient.getWebSocketUrl(), endsWith('/ws'));
      expect(
        ApiClient.getWebSocketUrl(),
        anyOf(startsWith('ws://'), startsWith('wss://')),
      );
    });
  });
}
