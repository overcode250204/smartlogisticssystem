import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/dispatch_management_page.dart'; // For DraggedPalletItem

class ResourcesColumn extends StatelessWidget {
  final bool isLoadingResources;
  final List<OrderModel> newOrders;
  final Function(int palletId, String orderCode) onRemoveOrderFromPallet;

  const ResourcesColumn({
    super.key,
    required this.isLoadingResources,
    required this.newOrders,
    required this.onRemoveOrderFromPallet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DragTarget<DraggedPalletItem>(
        onAccept: (draggedItem) {
          if (draggedItem.order.orderCode != null) {
            onRemoveOrderFromPallet(draggedItem.palletId, draggedItem.order.orderCode!);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? AppColors.success.withOpacity(0.1) : Colors.transparent,
              border: Border.all(color: candidateData.isNotEmpty ? AppColors.success : Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Bể chứa Đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                      child: Text('${newOrders.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Kéo thả đơn hàng vào chuyến xe hoặc pallet chờ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoadingResources
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: newOrders.length,
                          itemBuilder: (context, index) {
                            final order = newOrders[index];
                            return _buildDraggableOrder(order);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableOrder(OrderModel order) {
    return Draggable<OrderModel>(
      data: order,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(order.orderCode ?? 'Order', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildOrderCard(order),
      ),
      child: _buildOrderCard(order),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderCode ?? 'Tài liệu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('${order.totalWeightKg ?? 0}kg • ${order.deliveryProvince ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('NEW', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
