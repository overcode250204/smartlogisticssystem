import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/services/driver_profile_service.dart';

/// Resolves the logged-in driver's `driverId` (cached in SharedPreferences
/// after first lookup, since the backend has no `userId -> driverId` link
/// in the login response — see docs/local-trip-frontend-guide.md).
/// Throws a plain [Exception] with a Vietnamese message if the user has no
/// linked Driver record.
Future<int> resolveDriverId() async {
  final cached = await AuthSession.getDriverId();
  if (cached != null) return cached;

  final userId = await AuthSession.getUserId();
  if (userId == null) {
    throw Exception('Không tìm thấy phiên đăng nhập');
  }

  try {
    final driver = await DriverProfileService().getDriverByUserId(userId);
    await AuthSession.setDriverId(driver.driverId);
    return driver.driverId;
  } catch (_) {
    throw Exception('Tài khoản này chưa được liên kết với hồ sơ tài xế');
  }
}
