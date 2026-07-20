import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_product_service.dart';

class CustomerProductDetailScreen extends StatefulWidget {
  final int productId;

  const CustomerProductDetailScreen({super.key, required this.productId});

  @override
  State<CustomerProductDetailScreen> createState() => _CustomerProductDetailScreenState();
}

class _CustomerProductDetailScreenState extends State<CustomerProductDetailScreen> {
  final _productService = CustomerProductService();

  ProductResponse? _product;
  bool _loading = true;
  String _error = '';
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final product = await _productService.getProductById(widget.productId);
      if (mounted) setState(() { _product = product; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải sản phẩm: $e'; _loading = false; });
    }
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;
    setState(() => _addingToCart = true);
    await CartService.instance.load();
    await CartService.instance.addFromProduct(product, _quantity);
    setState(() => _addingToCart = false);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text('Đã thêm "${product.productName}" vào giỏ hàng')),
        ]),
        backgroundColor: CustomerColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: _load);
    if (_product == null) return const SizedBox();

    final product = _product!;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(children: [
            TextButton.icon(
              onPressed: () => context.go('/customer/products'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Sản phẩm'),
              style: TextButton.styleFrom(foregroundColor: CustomerColors.primary, padding: EdgeInsets.zero),
            ),
            const Icon(Icons.chevron_right, size: 16, color: CustomerColors.textSecondary),
            Expanded(child: Text(product.productName, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 16),
          // Main content
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: _buildImage(product)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildInfo(product, formatter)),
                ],
              );
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildImage(product),
              const SizedBox(height: 16),
              _buildInfo(product, formatter),
            ]);
          }),
          const SizedBox(height: 24),
          // Specs table
          CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông số kỹ thuật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
                const SizedBox(height: 12),
                _SpecRow('Mã sản phẩm', product.productCode),
                _SpecRow('SKU', product.sku),
                if (product.categoryName != null) _SpecRow('Danh mục', product.categoryName!),
                if (product.supplier != null) _SpecRow('Nhà cung cấp', product.supplier!.supplierName),
                if (product.weight != null) _SpecRow('Trọng lượng', '${product.weight} kg'),
                if (product.length != null) _SpecRow('Kích thước', '${product.length} × ${product.width} × ${product.height} cm'),
                if (product.baseUnitName != null) _SpecRow('Đơn vị', product.baseUnitName!),
                if (product.minStockLevel != null) _SpecRow('Tồn kho tối thiểu', '${product.minStockLevel}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(ProductResponse product) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomerCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: product.imageUrl != null
              ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emptyImage())
              : _emptyImage(),
        ),
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      color: CustomerColors.surfaceSecondary,
      child: const Center(child: Icon(Icons.inventory_2_outlined, size: 80, color: Color(0xFFCBD5E1))),
    );
  }

  Widget _buildInfo(ProductResponse product, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.categoryName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: CustomerColors.primaryLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(product.categoryName!, style: const TextStyle(color: CustomerColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 8),
        Text(product.productName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
        const SizedBox(height: 4),
        Text('SKU: ${product.sku}', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Text(formatter.format(product.price), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CustomerColors.primary)),
        if (product.baseUnitName != null)
          Text('/ ${product.baseUnitName}', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        const Divider(color: CustomerColors.border),
        const SizedBox(height: 16),
        // Quantity
        Row(
          children: [
            const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w500, color: CustomerColors.textPrimary)),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(border: Border.all(color: CustomerColors.border), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () { if (_quantity > 1) setState(() => _quantity--); },
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Icon(Icons.remove, size: 18, color: CustomerColors.primary)),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  InkWell(
                    onTap: () => setState(() => _quantity++),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Icon(Icons.add, size: 18, color: CustomerColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addingToCart ? null : _addToCart,
                icon: _addingToCart ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_shopping_cart),
                label: const Text('Thêm vào giỏ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _addToCart();
                  if (mounted) context.go('/customer/cart');
                },
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Mua ngay'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomerColors.primary,
                  side: const BorderSide(color: CustomerColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CustomerColors.textPrimary))),
        ],
      ),
    );
  }
}
