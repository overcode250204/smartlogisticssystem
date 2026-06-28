import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _productService = ProductService();

  bool _isLoading = true;
  String? _errorMessage;
  ProductResponse? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _productService.getProductById(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(ProductResponse product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa sản phẩm "${product.productName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _productService.deleteProduct(product.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa sản phẩm thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/products');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final errorMessage = _errorMessage;

    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? _ErrorState(message: errorMessage, onRetry: _loadProduct)
              : product == null
              ? _EmptyState(onBack: () => context.go('/products'))
              : _LoadedProductDetail(
                  product: product,
                  onBack: () => context.go('/products'),
                  onEdit: () => context.go('/products/${product.productId}/edit'),
                  onDelete: () => _deleteProduct(product),
                ),
        ),
      ),
    );
  }
}

class _LoadedProductDetail extends StatelessWidget {
  final ProductResponse product;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LoadedProductDetail({
    required this.product,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          onBack: onBack,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final left = Column(
                  children: [
                    _MainProductCard(product: product),
                    const SizedBox(height: 16),
                    _DetailsCard(product: product),
                  ],
                );
                final right = Column(
                  children: [
                    _BasicInfoCard(product: product),
                    const SizedBox(height: 16),
                    _ImageCard(product: product),
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [
                      left,
                      const SizedBox(height: 16),
                      right,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: right),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Header({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: compact ? constraints.maxWidth : constraints.maxWidth - 410,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard > Quản lý sản phẩm > Chi tiết sản phẩm',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chi tiết sản phẩm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Xem thông tin chi tiết của sản phẩm.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Quay lại'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Chỉnh sửa'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MainProductCard extends StatelessWidget {
  final ProductResponse product;

  const _MainProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final image = _ProductImage(url: product.imageUrl, size: compact ? 180 : 210);
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fallback(product.productName),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _MutedText('Mã sản phẩm: ${_fallback(product.productCode)}'),
              const SizedBox(height: 8),
              _MutedText('SKU: ${_fallback(product.sku)}'),
              if (_hasText(product.categoryName)) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Badge(label: _fallback(product.categoryName)),
                ),
              ],
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(height: 18),
                info,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              image,
              const SizedBox(width: 24),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }
}

class _BasicInfoCard extends StatelessWidget {
  final ProductResponse product;

  const _BasicInfoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Thông tin cơ bản',
      child: Column(
        children: [
          _InfoRow(icon: Icons.business_outlined, label: 'Nhà cung cấp', value: _supplierName(product)),
          _InfoRow(icon: Icons.category_outlined, label: 'Danh mục', value: _fallback(product.categoryName)),
          _InfoRow(icon: Icons.inventory_2_outlined, label: 'Đơn vị tính', value: _unitLabel(product)),
          _InfoRow(icon: Icons.qr_code_2, label: 'Mã sản phẩm', value: _fallback(product.productCode)),
          _InfoRow(icon: Icons.sell_outlined, label: 'SKU', value: _fallback(product.sku), isLast: true),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final ProductResponse product;

  const _DetailsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return _Card(
      title: 'Thông tin chi tiết',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final items = [
            _DetailItem(icon: Icons.payments_outlined, label: 'Giá bán', value: formatter.format(product.price)),
            _DetailItem(icon: Icons.scale_outlined, label: 'Trọng lượng', value: _numberWithUnit(product.weight, 'KG')),
            _DetailItem(icon: Icons.straighten_outlined, label: 'Kích thước', value: _dimensionLabel(product)),
            _DetailItem(icon: Icons.warning_amber_rounded, label: 'Tồn kho tối thiểu', value: product.minStockLevel?.toString() ?? '—'),
            _DetailItem(icon: Icons.business_outlined, label: 'Nhà cung cấp', value: _supplierName(product)),
            _DetailItem(icon: Icons.category_outlined, label: 'Danh mục', value: _fallback(product.categoryName)),
            _DetailItem(icon: Icons.inventory_2_outlined, label: 'Đơn vị tính', value: _unitLabel(product)),
          ];

          return Wrap(
            spacing: 18,
            runSpacing: 16,
            children: items
                .map(
                  (item) => SizedBox(
                    width: compact ? constraints.maxWidth : (constraints.maxWidth - 18) / 2,
                    child: item,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final ProductResponse product;

  const _ImageCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Hình ảnh sản phẩm',
      child: Align(
        alignment: Alignment.centerLeft,
        child: _ProductImage(url: product.imageUrl, size: 120),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Card({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cardTitle = title;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cardTitle != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Text(
                cardTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  final double size;

  const _ProductImage({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';
    if (imageUrl.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.inventory_2_outlined, size: size * 0.32, color: AppColors.textSecondary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 52),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 52),
          const SizedBox(height: 14),
          const Text('Không tìm thấy sản phẩm'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onBack, child: const Text('Quay lại danh sách')),
        ],
      ),
    );
  }
}

bool _hasText(String? value) => value?.trim().isNotEmpty == true;

String _fallback(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}

String _supplierName(ProductResponse product) => _fallback(product.supplier?.supplierName);

String _unitLabel(ProductResponse product) {
  final code = product.baseUnitCode?.trim();
  if (code != null && code.isNotEmpty) return code;
  return _fallback(product.baseUnitName);
}

String _numberWithUnit(double? value, String unit) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} $unit';
}

String _dimensionLabel(ProductResponse product) {
  String part(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  return '${part(product.length)} × ${part(product.width)} × ${part(product.height)}';
}
