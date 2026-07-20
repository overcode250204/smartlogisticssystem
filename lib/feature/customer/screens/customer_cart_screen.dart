import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final CartService _cart = CartService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    await _cart.load();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateQuantity(int productId, int qty) async {
    await _cart.updateQuantity(productId, qty);
    setState(() {});
  }

  Future<void> _remove(int productId) async {
    await _cart.remove(productId);
    setState(() {});
  }

  Future<void> _clear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giỏ hàng?'),
        content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm trong giỏ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.danger, foregroundColor: Colors.white),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _cart.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: CustomerColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Giỏ hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
                Text('${_cart.totalCount} sản phẩm', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
              ]),
              if (!_cart.isEmpty)
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline, size: 16, color: CustomerColors.danger),
                  label: const Text('Xóa tất cả', style: TextStyle(color: CustomerColors.danger)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: CustomerColors.border),
        // Content
        Expanded(
          child: _cart.isEmpty
              ? CustomerEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Giỏ hàng trống',
                  subtitle: 'Hãy thêm sản phẩm vào giỏ hàng!',
                  action: ElevatedButton.icon(
                    onPressed: () => context.go('/customer/products'),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Mua sắm ngay'),
                    style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.primary, foregroundColor: Colors.white),
                  ),
                )
              : LayoutBuilder(builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildItemList(formatter)),
                        Container(width: 1, color: CustomerColors.border),
                        SizedBox(width: 340, child: _buildSummary(formatter)),
                      ],
                    );
                  }
                  return Column(children: [
                    Expanded(child: _buildItemList(formatter)),
                    _buildSummary(formatter),
                  ]);
                }),
        ),
      ],
    );
  }

  Widget _buildItemList(NumberFormat formatter) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final item = _cart.items[idx];
        return CustomerCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image placeholder
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: CustomerColors.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E1), size: 32)),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E1), size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CustomerColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.productCode, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(formatter.format(item.price), style: const TextStyle(color: CustomerColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: CustomerColors.border), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _updateQuantity(item.productId, item.quantity - 1),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.remove, size: 16, color: CustomerColors.primary)),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        InkWell(
                          onTap: () => _updateQuantity(item.productId, item.quantity + 1),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.add, size: 16, color: CustomerColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(formatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: CustomerColors.textPrimary, fontSize: 13)),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _remove(item.productId),
                    child: const Icon(Icons.delete_outline, color: CustomerColors.danger, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: CustomerColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
          const SizedBox(height: 16),
          _SummaryRow('Số lượng', '${_cart.totalCount} sản phẩm'),
          _SummaryRow('Tổng trọng lượng', '${_cart.totalWeight.toStringAsFixed(2)} kg'),
          const Divider(color: CustomerColors.border),
          _SummaryRow('Tổng tiền', formatter.format(_cart.totalAmount), bold: true, valueColor: CustomerColors.primary),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/customer/checkout'),
              icon: const Icon(Icons.payment),
              label: const Text('Tiến hành đặt hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/customer/products'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Tiếp tục mua sắm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CustomerColors.primary,
                side: const BorderSide(color: CustomerColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: CustomerColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: valueColor ?? CustomerColors.textPrimary, fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }
}
