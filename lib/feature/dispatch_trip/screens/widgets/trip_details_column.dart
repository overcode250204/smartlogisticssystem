import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripHeader(
            '${trip.linehaultripCode ?? "N/A"}',
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
            onCanStart: onUpdateStatusToCanStart != null && trip.linehaulId != null
                ? () => onUpdateStatusToCanStart!(trip.linehaulId!)
                : null,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DragTarget<PalletModel>(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text('Danh sách Pallet trên xe (${trip.pallets?.length ?? 0})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: trip.pallets?.length ?? 0,
                          itemBuilder: (context, index) {
                            final pallet = trip.pallets![index];
                            return _buildLinehaulPalletCard(pallet);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      final trip = selectedTrip as LocalTripModel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripHeader(
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text('Danh sách Đơn hàng (VRP Order)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: trip.details?.length ?? 0,
                    itemBuilder: (context, index) {
                      final detail = trip.details![index];
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
                    },
                  ),
                ),
              ],
            ),
          ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
            Row(
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
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(Icons.person_outline, driver, ''),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoBox(Icons.local_shipping_outlined, 'Biển số xe', vehicle ?? 'Chưa phân công'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoBox(Icons.info_outline, 'Trạng thái', statusLabel),
            ),
            if (vrpEstimatedMinutes != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoBox(Icons.timer_outlined, 'VRP Dự kiến', '$vrpEstimatedMinutes phút'),
              ),
            ],
          ],
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
                  Text(title.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            title: Text(pallet.palletCode ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${pallet.palletItems?.length ?? 0} kiện • ${pallet.totalWeightKg ?? 0}kg'),
            shape: const Border(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pallet.status != null) ...[
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
                  const SizedBox(width: 8),
                ],
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
