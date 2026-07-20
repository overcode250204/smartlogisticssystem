import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_order_service.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const CustomerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  final _orderService = CustomerOrderService();
  OrderModel? _order;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final order = await _orderService.getMyOrderById(widget.orderId);
      if (mounted) setState(() { _order = order; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải đơn hàng: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: _load);
    if (_order == null) return const SizedBox();

    final order = _order!;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateStr = order.createdAt.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order.createdAt))
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(children: [
            TextButton.icon(
              onPressed: () => context.go('/customer/orders'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Đơn hàng'),
              style: TextButton.styleFrom(foregroundColor: CustomerColors.primary, padding: EdgeInsets.zero),
            ),
            const Icon(Icons.chevron_right, size: 16, color: CustomerColors.textSecondary),
            Expanded(child: Text(order.orderCode, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 16),

          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [CustomerColors.primary, CustomerColors.accent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.orderCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(dateStr, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                  ]),
                ),
                CustomerStatusBadge(status: order.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/customer/orders/${order.orderId}/tracking'),
                icon: const Icon(Icons.location_searching, size: 16),
                label: const Text('Theo dõi giao hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Info cards
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDeliveryInfo(order)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPaymentInfo(order, formatter)),
                ],
              );
            }
            return Column(children: [
              _buildDeliveryInfo(order),
              const SizedBox(height: 12),
              _buildPaymentInfo(order, formatter),
            ]);
          }),
          const SizedBox(height: 16),

          // Items
          CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sản phẩm (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
                const SizedBox(height: 12),
                ...order.items.map((item) => _ItemRow(item: item, formatter: formatter)),
                const Divider(color: CustomerColors.border),
                _TotalRow('Tổng trọng lượng', '${order.totalWeightKg.toStringAsFixed(2)} kg'),
                _TotalRow('Tổng thể tích', '${order.totalVolumeM3.toStringAsFixed(4)} m³'),
                _TotalRow('Tổng tiền', formatter.format(order.totalAmount), bold: true, color: CustomerColors.primary),
              ],
            ),
          ),

          if (order.expectedDeliveryTime != null || order.actualDeliveryTime != null) ...[
            const SizedBox(height: 16),
            CustomerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thời gian giao hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (order.expectedDeliveryTime != null)
                    _InfoRow(Icons.schedule, 'Dự kiến giao', _formatDate(order.expectedDeliveryTime!)),
                  if (order.actualDeliveryTime != null)
                    _InfoRow(Icons.check_circle_outline, 'Đã giao lúc', _formatDate(order.actualDeliveryTime!)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin giao hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
          const SizedBox(height: 12),
          _InfoRow(Icons.person_outline, 'Khách hàng', order.customerName),
          _InfoRow(Icons.phone_outlined, 'Số điện thoại', order.phone),
          _InfoRow(Icons.location_on_outlined, 'Địa chỉ', order.deliveryAddress),
          _InfoRow(Icons.map_outlined, 'Tỉnh/TP', order.deliveryProvince),
          if (order.assignedHub != null)
            _InfoRow(Icons.warehouse_outlined, 'Kho phụ trách', order.assignedHub!.name),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderModel order, NumberFormat formatter) {
    return CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
          const SizedBox(height: 12),
          _InfoRow(Icons.payment_outlined, 'Phương thức', order.paymentType == 'COD' ? 'COD - Thanh toán khi nhận' : order.paymentType),
          _InfoRow(Icons.attach_money, 'Tổng tiền', formatter.format(order.totalAmount)),
          if (order.barcodeUrl != null)
            _InfoRow(Icons.qr_code_outlined, 'Mã vạch', 'Có mã vạch'),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CustomerColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CustomerColors.textPrimary))),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItemModel item;
  final NumberFormat formatter;

  const _ItemRow({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: CustomerColors.surfaceSecondary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.inventory_2_outlined, color: CustomerColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CustomerColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('${formatter.format(item.unitPrice)} × ${item.quantityOrdered}', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12)),
            ]),
          ),
          Text(formatter.format(item.unitPrice * item.quantityOrdered), style: const TextStyle(fontWeight: FontWeight.bold, color: CustomerColors.primary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _TotalRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: CustomerColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color ?? CustomerColors.textPrimary, fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }
}
