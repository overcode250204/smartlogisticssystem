import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';

/// Trạng thái pallet theo enum backend (PalletStatus.java):
/// CREATING, CAN_SEAL, SEALED, IN_TRANSIT, ARRIVED.
///
/// Toàn bộ rule hiển thị/thao tác của màn hình Staff tập trung tại đây để
/// tránh rải điều kiện khắp các widget.
class PalletTaskState {
  final PalletModel pallet;
  final List<PalletItemModel> items;

  PalletTaskState(this.pallet)
    : items = List<PalletItemModel>.unmodifiable(
        pallet.palletItems ?? const <PalletItemModel>[],
      );

  String get rawStatus => pallet.status ?? '';

  PalletStatus? get status {
    for (final value in PalletStatus.values) {
      if (value.name == rawStatus) return value;
    }
    return null;
  }

  String get statusLabel => status?.displayName ?? (rawStatus.isEmpty ? 'N/A' : rawStatus);

  int get totalCount => items.length;

  int get scannedCount => items.where((item) => item.isScanned).length;

  int get remainingCount => totalCount - scannedCount;

  double get progress => totalCount == 0 ? 0 : scannedCount / totalCount;

  bool get allScanned => totalCount > 0 && scannedCount == totalCount;

  /// Backend: `scanPalletItem` chỉ chấp nhận pallet ở trạng thái CAN_SEAL.
  bool get canScan => status == PalletStatus.CAN_SEAL;

  /// Backend: `updateStatusToCanSeal` yêu cầu CREATING và pallet có item.
  bool get canMarkCanSeal => status == PalletStatus.CREATING && totalCount > 0;

  /// Backend: `makeSealed` yêu cầu CAN_SEAL, có item và tất cả item đã scan.
  /// Đây là điều kiện *tối thiểu* để bật nút; backend vẫn là source of truth
  /// và có thể từ chối với lỗi cụ thể.
  bool get canSeal => status == PalletStatus.CAN_SEAL && allScanned;

  /// Sau SEALED thì staff không còn thao tác đóng gói nào nữa.
  bool get isReadOnly =>
      status == PalletStatus.SEALED ||
      status == PalletStatus.IN_TRANSIT ||
      status == PalletStatus.ARRIVED;

  /// Lý do chưa thể seal, hiển thị cho staff. Rỗng nghĩa là đủ điều kiện.
  List<String> get sealBlockers {
    final reasons = <String>[];
    if (totalCount == 0) {
      reasons.add('Pallet chưa có đơn hàng nào.');
    }
    if (status == PalletStatus.CREATING) {
      reasons.add('Pallet chưa mở quét. Bấm "Bắt đầu quét" để chuyển sang CAN_SEAL.');
    }
    if (status == PalletStatus.CAN_SEAL && remainingCount > 0) {
      reasons.add('Còn $remainingCount đơn chưa quét.');
    }
    if (isReadOnly) {
      reasons.add('Pallet ở trạng thái "$statusLabel", không thể seal lại.');
    }
    return reasons;
  }

  // ---------------------------------------------------------------------------
  // Nhận hàng (arrival) — 2 endpoint ĐỘC LẬP với nhau theo backend:
  //   confirmPalletArrival: pallet IN_TRANSIT -> ARRIVED (KHÔNG đổi order).
  //   confirmOrderArrival : order IN_TRANSIT_LINEHAUL -> ARRIVED_AT_HUB
  //                         (KHÔNG đổi trạng thái pallet).
  // Cả hai yêu cầu body GPS {latitude, longitude} và ở gần kho đích (≤500m).
  // ---------------------------------------------------------------------------

  static const String _orderInTransit = 'IN_TRANSIT_LINEHAUL';
  static const String _orderArrived = 'ARRIVED_AT_HUB';

  /// Chỉ hiển thị khu vực nhận hàng khi pallet đã lên đường hoặc đã đến.
  bool get showArrivalSection =>
      status == PalletStatus.IN_TRANSIT || status == PalletStatus.ARRIVED;

  /// Backend: confirmPalletArrival yêu cầu pallet đang IN_TRANSIT.
  bool get canConfirmPalletArrival => status == PalletStatus.IN_TRANSIT;

  bool get isPalletArrived => status == PalletStatus.ARRIVED;

  /// Khu vực nhận hàng chuyển read-only khi pallet đã ARRIVED.
  bool get isArrivalReadOnly => isPalletArrived;

  String orderStatus(PalletItemModel item) => item.order?.status ?? '';

  /// Backend: confirmOrderArrival yêu cầu order đang IN_TRANSIT_LINEHAUL.
  bool canConfirmOrderArrival(PalletItemModel item) =>
      orderStatus(item) == _orderInTransit;

  bool isOrderArrived(PalletItemModel item) =>
      orderStatus(item) == _orderArrived;

  int get arrivedOrderCount => items.where(isOrderArrived).length;

  int get pendingArrivalCount => totalCount - arrivedOrderCount;

  double get arrivalProgress =>
      totalCount == 0 ? 0 : arrivedOrderCount / totalCount;

  /// Danh sách mã đơn chưa quét (dùng để nhắc staff).
  List<String> get unscannedOrderCodes => items
      .where((item) => !item.isScanned)
      .map((item) => item.order?.orderCode ?? '—')
      .toList();

  /// Ưu tiên hiển thị đơn chưa quét trước, sau đó sắp theo orderCode để
  /// thứ tự ổn định (backend không cam kết thứ tự trả về).
  List<PalletItemModel> sortedItems({String query = ''}) {
    final normalized = query.trim().toUpperCase();
    final filtered = items.where((item) {
      if (normalized.isEmpty) return true;
      return (item.order?.orderCode ?? '').toUpperCase().contains(normalized);
    }).toList();

    filtered.sort((a, b) {
      if (a.isScanned != b.isScanned) return a.isScanned ? 1 : -1;
      return (a.order?.orderCode ?? '').compareTo(b.order?.orderCode ?? '');
    });
    return filtered;
  }
}

Color palletStatusColor(PalletStatus? status) {
  return switch (status) {
    PalletStatus.CREATING => Colors.orange,
    PalletStatus.CAN_SEAL => Colors.blue,
    PalletStatus.SEALED => Colors.green,
    PalletStatus.IN_TRANSIT => Colors.purple,
    PalletStatus.ARRIVED => Colors.teal,
    null => Colors.grey,
  };
}

IconData palletStatusIcon(PalletStatus? status) {
  return switch (status) {
    PalletStatus.CREATING => Icons.edit_note,
    PalletStatus.CAN_SEAL => Icons.qr_code_scanner,
    PalletStatus.SEALED => Icons.lock,
    PalletStatus.IN_TRANSIT => Icons.local_shipping,
    PalletStatus.ARRIVED => Icons.warehouse,
    null => Icons.help_outline,
  };
}

/// Badge trạng thái dùng chung cho list và detail. Không chỉ dựa vào màu:
/// luôn kèm icon + nhãn chữ (accessibility).
class PalletStatusBadge extends StatelessWidget {
  final PalletStatus? status;
  final String label;

  const PalletStatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = palletStatusColor(status);
    return Semantics(
      label: 'Trạng thái pallet: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(palletStatusIcon(status), size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
