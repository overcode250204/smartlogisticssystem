import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';

/// Kiểm tra phân công tài xế của một chuyến linehaul có hợp lệ không, dựa trên
/// dữ liệu backend trả về. Dùng để CẢNH BÁO dữ liệu cũ không hợp lệ và KHOÁ nút
/// "XUẤT BẾN" ở frontend. Backend vẫn là nơi chặn cuối cùng.
///
/// Quy tắc (khớp validator backend):
///  - Mỗi tài xế chỉ xuất hiện tối đa một lần (chặn: chính kiêm phụ, phụ trùng).
///  - Tối đa một tài xế chính (MAIN).
class DriverAssignmentValidation {
  final List<String> issues;

  const DriverAssignmentValidation(this.issues);

  bool get isValid => issues.isEmpty;
}

DriverAssignmentValidation validateLinehaulAssignment(
  List<LinehaulTripDriverModel>? drivers,
) {
  final issues = <String>[];
  if (drivers == null || drivers.isEmpty) {
    return const DriverAssignmentValidation([]);
  }

  // Trùng tài xế trong cùng chuyến (bất kể role).
  final seen = <int>{};
  final duplicated = <int>{};
  for (final td in drivers) {
    final id = td.driver?.driverId;
    if (id == null) continue;
    if (!seen.add(id)) duplicated.add(id);
  }
  if (duplicated.isNotEmpty) {
    issues.add('Có tài xế bị phân công trùng trong chuyến.');
  }

  // Nhiều hơn một tài xế chính.
  final mainCount = drivers.where((td) => td.role == 'MAIN').length;
  if (mainCount > 1) {
    issues.add('Chuyến có nhiều hơn một tài xế chính (MAIN).');
  }

  return DriverAssignmentValidation(issues);
}
