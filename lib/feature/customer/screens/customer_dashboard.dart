import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_order_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_product_service.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _orderService = CustomerOrderService();
  final _productService = CustomerProductService();

  List<OrderModel> _orders = [];
  int _totalProducts = 0;
  bool _loading = true;
  String _error = '';
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final user = await AuthSession.getCurrentUser();
      final orders = await _orderService.getMyOrders();
      final products = await _productService.getProductsPage(size: 1);
      if (mounted) {
        setState(() {
          _fullName = user?.displayName ?? 'Khách hàng';
          _orders = orders;
          _totalProducts = products.totalElements;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải dữ liệu: $e'; _loading = false; });
    }
  }

  Map<String, int> get _statusCounts {
    final counts = <String, int>{};
    for (final o in _orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: _load);

    final recentOrders = _orders.take(3).toList();
    final statusCounts = _statusCounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CustomerColors.primary, CustomerColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, $_fullName! 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Chào mừng bạn đến với SmartLogistics',
                        style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/customer/products'),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                        label: const Text('Mua sắm ngay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: CustomerColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.local_shipping, size: 80, color: Color(0x33FFFFFF)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.receipt_long, label: 'Tổng đơn hàng', value: '${_orders.length}', color: CustomerColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.local_shipping, label: 'Đang giao', value: '${(statusCounts['IN_TRANSIT'] ?? 0) + (statusCounts['PROCESSING'] ?? 0)}', color: const Color(0xFF7C3AED))),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.check_circle, label: 'Đã giao', value: '${statusCounts['DELIVERED'] ?? 0}', color: CustomerColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(icon: Icons.inventory_2, label: 'Sản phẩm', value: '$_totalProducts', color: CustomerColors.warning)),
            ],
          ),

          const SizedBox(height: 20),

          // Quick actions
          Row(
            children: [
              Expanded(child: _QuickActionCard(
                icon: Icons.search,
                label: 'Tìm sản phẩm',
                color: CustomerColors.primary,
                onTap: () => context.go('/customer/products'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(
                icon: Icons.shopping_cart,
                label: 'Giỏ hàng',
                color: CustomerColors.accent,
                onTap: () => context.go('/customer/cart'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(
                icon: Icons.receipt_long,
                label: 'Đơn hàng',
                color: const Color(0xFF7C3AED),
                onTap: () => context.go('/customer/orders'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(
                icon: Icons.person,
                label: 'Tài khoản',
                color: CustomerColors.success,
                onTap: () => context.go('/customer/profile'),
              )),
            ],
          ),

          const SizedBox(height: 20),

          // Recent orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đơn hàng gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
              TextButton(onPressed: () => context.go('/customer/orders'), child: const Text('Xem tất cả →')),
            ],
          ),
          const SizedBox(height: 8),

          if (recentOrders.isEmpty)
            CustomerCard(
              child: CustomerEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có đơn hàng',
                subtitle: 'Hãy đặt hàng đầu tiên của bạn!',
                action: ElevatedButton(
                  onPressed: () => context.go('/customer/products'),
                  style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.primary, foregroundColor: Colors.white),
                  child: const Text('Mua sắm ngay'),
                ),
              ),
            )
          else
            ...recentOrders.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomerCard(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () => context.go('/customer/orders/${o.orderId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: CustomerColors.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_outlined, color: CustomerColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.orderCode, style: const TextStyle(fontWeight: FontWeight.w600, color: CustomerColors.textPrimary)),
                            Text(o.deliveryAddress, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomerStatusBadge(status: o.status),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(o.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: CustomerColors.primary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomerCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: CustomerColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomerCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CustomerColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
