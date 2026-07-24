import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/services/driver_assignment_rules.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/dispatch_management_page.dart'; // For DraggedPalletItem

class TripDetailsColumn extends StatelessWidget {
  final dynamic selectedTrip;
  final VoidCallback? onEditLinehaul;
  final VoidCallback? onEditLocal;
  final VoidCallback? onCollapseLocal;
  final Function(int linehaulId, int palletId) onAddPalletToLinehaul;
  final Function(int palletId, String orderCode) onAddOrderToPallet;
  final Function(int tripId)? onDeleteLinehaul;
  final Function(int tripId)? onUpdateStatusToCanStart;
  final Function(int palletId)? onDeletePallet;
  final Function(int palletId)? onUpdateStatusToCanSeal;

  const TripDetailsColumn({
    super.key,
    required this.selectedTrip,
    this.onEditLinehaul,
    this.onEditLocal,
    this.onCollapseLocal,
    required this.onAddPalletToLinehaul,
    required this.onAddOrderToPallet,
    this.onDeleteLinehaul,
    this.onUpdateStatusToCanStart,
    this.onDeletePallet,
    this.onUpdateStatusToCanSeal,
  });


  Color _getPalletStatusColor(String? statusStr) {
    if (statusStr == null) return Colors.grey;
    try {
      final status = PalletStatus.values.firstWhere((e) => e.name == statusStr);
      switch (status) {
        case PalletStatus.CREATING:
          return Colors.orange;
        case PalletStatus.SEALED:
          return Colors.blue;
        case PalletStatus.IN_TRANSIT:
          return Colors.indigo;
        case PalletStatus.ARRIVED:
          return Colors.green;
        case PalletStatus.CAN_SEAL:
          return Colors.brown;
      }
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getPalletStatusDisplayName(String? statusStr) {
    if (statusStr == null) return 'N/A';
    try {
      final status = PalletStatus.values.firstWhere((e) => e.name == statusStr);
      return status.displayName;
    } catch (_) {
      return statusStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTrip == null) {
      return const Center(
        child: Text('Chọn một chuyến đi để xem chi tiết', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    if (selectedTrip is LinehaulTripModel) {
      final trip = selectedTrip as LinehaulTripModel;
      // Dữ liệu cũ có thể chứa phân công không hợp lệ (trùng driver / nhiều MAIN).
      // Khi đó khoá nút XUẤT BẾN và hiển thị cảnh báo, không để crash.
      final assignmentIssues =
          validateLinehaulAssignment(trip.linehaulTripDriver);
      final header = _buildTripHeader(
            trip.linehaultripCode ?? "N/A",
            'LINEHAUL',
            trip.routeConfig?.routeName ?? 'N/A',
            trip.linehaulTripDriver?.isNotEmpty == true
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: trip.linehaulTripDriver!.map((d) {
                      String roleText = d.role == 'MAIN' ? 'Tài xế chính' : 'Tài xế phụ';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.driver?.name ?? "N/A"} ($roleText)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (d.driver?.phone != null)
                              Text(
                                d.driver!.phone!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : 'Chưa phân công',
            trip.vehicle?.licensePlate,
            trip.status?.displayName ?? 'N/A',
            onEdit: onEditLinehaul,
            onDelete: onDeleteLinehaul != null && trip.linehaulId != null
                ? () => onDeleteLinehaul!(trip.linehaulId!)
                : null,
            // Chặn xuất bến ở FE khi phân công không hợp lệ (backend vẫn chặn cuối).
            onCanStart: assignmentIssues.isValid &&
                    onUpdateStatusToCanStart != null &&
                    trip.linehaulId != null
                ? () => onUpdateStatusToCanStart!(trip.linehaulId!)
                : null,
            assignmentIssues: assignmentIssues.issues,
          );
      final pallets = trip.pallets ?? const [];
      return DragTarget<PalletModel>(
        onAccept: (pallet) {
          if (pallet.palletId != null && trip.linehaulId != null) {
            onAddPalletToLinehaul(trip.linehaulId!, pallet.palletId!);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: candidateData.isNotEmpty ? AppColors.primary : Colors.transparent, width: 2),
            ),
            // Toàn bộ cột chi tiết cuộn được để không tràn khi nội dung header
            // hoặc danh sách pallet dài hơn khoảng trống được cấp.
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              children: [
                header,
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Danh sách Pallet trên xe (${pallets.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pallets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Kéo pallet chờ xếp vào đây',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...pallets.map(_buildLinehaulPalletCard),
              ],
            ),
          );
        },
      );
    } else {
      final trip = selectedTrip as LocalTripModel;
      final header = _buildTripHeader(
            trip.localTripCode ?? 'LM-${trip.localTripId ?? "000"}',
            'LAST-MILE',
            trip.hub?.name ?? 'N/A',
            trip.driver != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.driver!.name ?? 'Chưa phân công',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (trip.driver!.phone != null)
                        Text(
                          trip.driver!.phone!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  )
                : 'Chưa phân công',
            trip.vehicle?.licensePlate,
            trip.status?.displayName ?? 'N/A',
            onEdit: onEditLocal,
            onCollapse: onCollapseLocal,
            vrpEstimatedMinutes: trip.vrpEstimatedMinutes,
          );
      final details = trip.details ?? const [];
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          header,
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Danh sách Đơn hàng (VRP Order)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.asMap().entries.map((entry) {
            final index = entry.key;
            final detail = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.darkest,
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.textPrimary)),
                ),
                title: Text(detail.order?.orderCode ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${detail.order?.totalWeightKg ?? 0}kg • ${detail.order?.deliveryProvince ?? ""}'),
              ),
            );
          }),
        ],
      );
    }
  }

  Widget _buildTripHeader(
    String title,
    String typeLabel,
    String subtitle,
    dynamic driver,
    String? vehicle,
    String statusLabel, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onCanStart,
    VoidCallback? onCollapse,
    int? vrpEstimatedMinutes,
    List<String> assignmentIssues = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assignmentIssues.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Phân công tài xế không hợp lệ — không thể xuất bến. '
                        'Vui lòng sửa lại phân công.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                for (final issue in assignmentIssues)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 24),
                    child: Text('• $issue'),
                  ),
              ],
            ),
          ),
        // Dùng Wrap để tiêu đề và các nút hành động xuống dòng thay vì tràn ngang
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(typeLabel, style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: onEdit,
                    tooltip: 'Sửa chuyến',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Xóa chuyến',
                  ),
                if (typeLabel == 'LINEHAUL')
                  OutlinedButton.icon(
                    onPressed: onCanStart,
                    icon: const Text('XUẤT BẾN'),
                    label: const Icon(Icons.play_arrow),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      backgroundColor: Colors.white,
                    ),
                  ),
                if (typeLabel == 'LAST-MILE' && onCollapse != null)
                  OutlinedButton.icon(
                    onPressed: onCollapse,
                    icon: const Text('GỘP CHUYẾN'),
                    label: const Icon(Icons.merge_type),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      backgroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        // Các ô thông tin tự xuống dòng khi cột chi tiết bị thu hẹp,
        // tránh việc chữ bị bẻ theo từng ký tự và tràn chiều dọc.
        LayoutBuilder(
          builder: (context, constraints) {
            final boxes = <Widget>[
              _buildInfoBox(Icons.person_outline, driver, ''),
              _buildInfoBox(Icons.local_shipping_outlined, 'Biển số xe', vehicle ?? 'Chưa phân công'),
              _buildInfoBox(Icons.info_outline, 'Trạng thái', statusLabel),
              if (vrpEstimatedMinutes != null)
                _buildInfoBox(Icons.timer_outlined, 'VRP Dự kiến', '$vrpEstimatedMinutes phút'),
            ];
            const spacing = 8.0;
            const minBoxWidth = 200.0;
            final maxWidth = constraints.maxWidth;
            var perRow = ((maxWidth + spacing) / (minBoxWidth + spacing)).floor();
            perRow = perRow.clamp(1, boxes.length);
            final boxWidth = (maxWidth - spacing * (perRow - 1)) / perRow;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: boxes
                  .map((b) => SizedBox(width: boxWidth, child: b))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoBox(IconData icon, dynamic title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.darkest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title is Widget)
                  title
                else
                  Text(title.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinehaulPalletCard(PalletModel pallet) {
    return Draggable<PalletModel>(
      data: pallet,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(pallet.palletCode ?? 'Pallet', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildLinehaulPalletCardBody(pallet),
      ),
      child: _buildLinehaulPalletCardBody(pallet),
    );
  }

  Widget _buildLinehaulPalletCardBody(PalletModel pallet) {
    return DragTarget<OrderModel>(
      onAccept: (order) {
        if (pallet.palletId != null && order.orderCode != null) {
          onAddOrderToPallet(pallet.palletId!, order.orderCode!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppColors.success.withOpacity(0.1) : Colors.white,
            border: Border.all(color: candidateData.isNotEmpty ? AppColors.success : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2, color: AppColors.textSecondary),
            title: Text(
              pallet.palletCode ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Badge trạng thái nằm ở subtitle để không chiếm hết bề ngang của title
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${pallet.palletItems?.length ?? 0} kiện • ${pallet.totalWeightKg ?? 0}kg'),
                if (pallet.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPalletStatusColor(pallet.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPalletStatusDisplayName(pallet.status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPalletStatusColor(pallet.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            shape: const Border(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pallet.status == 'CREATING') ...[
                  IconButton(
                    icon: const Icon(Icons.lock_open, size: 18, color: AppColors.primary),
                    onPressed: onUpdateStatusToCanSeal != null && pallet.palletId != null
                        ? () => onUpdateStatusToCanSeal!(pallet.palletId!)
                        : null,
                    tooltip: 'Sẵn sàng niêm phong (Can Seal)',
                  ),
                ],
                if (onDeletePallet != null && pallet.palletId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => onDeletePallet!(pallet.palletId!),
                    tooltip: 'Xóa Pallet',
                  ),
              ],
            ),
            children: pallet.palletItems?.map((item) {
              final order = item.order;
              if (order == null) return const SizedBox();
              return Draggable<DraggedPalletItem>(
                data: DraggedPalletItem(palletId: pallet.palletId!, order: order),
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Order #${order.orderCode ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: ListTile(
                    title: Text('Order #${order.orderCode ?? "N/A"}'),
                  ),
                ),
                child: ListTile(
                  title: Text('Order #${order.orderCode ?? "N/A"}'),
                  trailing: const Icon(Icons.drag_indicator, size: 16),
                ),
              );
            }).toList() ?? [],
          ),
        );
      },
    );
  }
}
