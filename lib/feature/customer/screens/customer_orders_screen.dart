import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_order_service.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _orderService = CustomerOrderService();

  List<OrderModel> _orders = [];
  List<OrderModel> _filtered = [];
  bool _loading = true;
  String _error = '';
  String _filterStatus = 'ALL';

  static const _statuses = [
    ('ALL', 'Tất cả'),
    ('NEW', 'Mới'),
    ('CONFIRMED', 'Xác nhận'),
    ('PROCESSING', 'Xử lý'),
    ('IN_TRANSIT', 'Đang giao'),
    ('DELIVERED', 'Đã giao'),
    ('COMPLETED', 'Hoàn thành'),
    ('CANCELLED', 'Đã hủy'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final orders = await _orderService.getMyOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _filtered = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải đơn hàng: $e'; _loading = false; });
    }
  }

  void _filter(String status) {
    setState(() {
      _filterStatus = status;
      _filtered = status == 'ALL' ? _orders : _orders.where((o) => o.status == status).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          color: CustomerColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${_orders.length} đơn hàng', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses.map((s) {
                    final (value, label) = s;
                    final selected = _filterStatus == value;
                    final count = value == 'ALL' ? _orders.length : _orders.where((o) => o.status == value).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _filter(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? CustomerColors.primary : CustomerColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? CustomerColors.primary : CustomerColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(label, style: TextStyle(color: selected ? Colors.white : CustomerColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                              if (count > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white.withValues(alpha: 0.3) : CustomerColors.border,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$count', style: TextStyle(color: selected ? Colors.white : CustomerColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(height: 1, color: CustomerColors.border),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: _load);
    if (_filtered.isEmpty) {
      return CustomerEmptyState(
        icon: Icons.receipt_long_outlined,
        title: _filterStatus == 'ALL' ? 'Chưa có đơn hàng' : 'Không có đơn hàng',
        subtitle: _filterStatus == 'ALL' ? 'Đặt hàng ngay để bắt đầu!' : 'Không tìm thấy đơn hàng với trạng thái này',
        action: _filterStatus == 'ALL'
            ? ElevatedButton(
                onPressed: () => context.go('/customer/products'),
                style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.primary, foregroundColor: Colors.white),
                child: const Text('Mua sắm ngay'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      color: CustomerColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) => _OrderCard(order: _filtered[idx]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateStr = order.createdAt.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order.createdAt))
        : '';

    return InkWell(
      onTap: () => context.go('/customer/orders/${order.orderId}'),
      borderRadius: BorderRadius.circular(12),
      child: CustomerCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: CustomerColors.textPrimary)),
                CustomerStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: CustomerColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(order.deliveryAddress, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: CustomerColors.textSecondary),
              const SizedBox(width: 4),
              Text(dateStr, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            const Divider(color: CustomerColors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.items.length} sản phẩm • ${order.totalWeightKg.toStringAsFixed(1)} kg', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12)),
                Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: CustomerColors.primary, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/customer/orders/${order.orderId}'),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CustomerColors.primary,
                    side: const BorderSide(color: CustomerColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/customer/orders/${order.orderId}/tracking'),
                  icon: const Icon(Icons.location_searching, size: 14),
                  label: const Text('Theo dõi', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
