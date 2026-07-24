import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/services/driver_assignment_rules.dart';

LinehaulTripDriverModel td(int driverId, String role) => LinehaulTripDriverModel(
      id: driverId,
      driver: DriverModel(driverId: driverId, name: 'D$driverId'),
      role: role,
    );

void main() {
  group('validateLinehaulAssignment (TC-DRIVER-041 helper)', () {
    test('null / rỗng -> hợp lệ', () {
      expect(validateLinehaulAssignment(null).isValid, isTrue);
      expect(validateLinehaulAssignment(const []).isValid, isTrue);
    });

    test('1 MAIN + 1 ASSISTANT khác nhau -> hợp lệ', () {
      final v = validateLinehaulAssignment([td(1, 'MAIN'), td(2, 'ASSISTANT')]);
      expect(v.isValid, isTrue);
    });

    test('cùng driver ở MAIN và ASSISTANT -> không hợp lệ', () {
      final v = validateLinehaulAssignment([td(1, 'MAIN'), td(1, 'ASSISTANT')]);
      expect(v.isValid, isFalse);
      expect(v.issues.join(), contains('trùng'));
    });

    test('nhiều MAIN -> không hợp lệ', () {
      final v = validateLinehaulAssignment([td(1, 'MAIN'), td(2, 'MAIN')]);
      expect(v.isValid, isFalse);
      expect(v.issues.join(), contains('tài xế chính'));
    });

    test('duplicate assistant -> không hợp lệ', () {
      final v = validateLinehaulAssignment([
        td(1, 'MAIN'),
        td(2, 'ASSISTANT'),
        td(2, 'ASSISTANT'),
      ]);
      expect(v.isValid, isFalse);
    });
  });
}
