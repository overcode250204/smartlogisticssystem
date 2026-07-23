import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_product_service.dart';

class CustomerProductsScreen extends StatefulWidget {
  const CustomerProductsScreen({super.key});

  @override
  State<CustomerProductsScreen> createState() => _CustomerProductsScreenState();
}

class _CustomerProductsScreenState extends State<CustomerProductsScreen> {
  final _productService = CustomerProductService();
  final _searchController = TextEditingController();

  List<ProductResponse> _products = [];
  List<ProductCategoryResponse> _categories = [];
  int _selectedCategoryId = 0;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = ''; _page = 0; });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final result = await _productService.getProductsPage(
        page: reset ? 0 : _page,
        size: 12,
        keyword: _keyword.isEmpty ? null : _keyword,
        categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _products = result.content;
          } else {
            _products.addAll(result.content);
          }
          _page = result.page + 1;
          _totalPages = result.totalPages;
          _totalElements = result.totalElements;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Lỗi tải sản phẩm: $e'; _loading = false; _loadingMore = false; });
    }
  }

  void _search() {
    _keyword = _searchController.text.trim();
    _loadProducts(reset: true);
  }

  Future<void> _addToCart(ProductResponse product) async {
    await CartService.instance.load();
    await CartService.instance.addFromProduct(product, 1);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          color: CustomerColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Danh mục sản phẩm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
              const SizedBox(height: 4),
              Text('$_totalElements sản phẩm có sẵn', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              // Search
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CustomerColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CustomerColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CustomerColors.primary)),
                      isDense: true,
                      filled: true,
                      fillColor: CustomerColors.surfaceSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Tìm'),
                ),
              ]),
              const SizedBox(height: 12),
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(label: 'Tất cả', selected: _selectedCategoryId == 0, onTap: () { setState(() => _selectedCategoryId = 0); _loadProducts(reset: true); }),
                    ..._categories.map((c) => _CategoryChip(
                      label: c.categoryName,
                      selected: _selectedCategoryId == c.categoryId,
                      onTap: () { setState(() => _selectedCategoryId = c.categoryId); _loadProducts(reset: true); },
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: () => _loadProducts(reset: true));
    if (_products.isEmpty) return CustomerEmptyState(icon: Icons.inventory_2_outlined, title: 'Không có sản phẩm', subtitle: 'Thử tìm kiếm với từ khóa khác');

    return RefreshIndicator(
      color: CustomerColors.primary,
      onRefresh: () => _loadProducts(reset: true),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) {
                  if (idx >= _products.length) {
                    if (_loadingMore) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
                    return null;
                  }
                  return _ProductCard(product: _products[idx], onAddToCart: () => _addToCart(_products[idx]));
                },
                childCount: _products.length + (_loadingMore ? 1 : 0),
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
            ),
          ),
          if (!_loadingMore && _page < _totalPages)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadProducts(),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Xem thêm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomerColors.primary, foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? CustomerColors.primary : CustomerColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? CustomerColors.primary : CustomerColors.border),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : CustomerColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductResponse product;
  final VoidCallback onAddToCart;

  const _ProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return InkWell(
      onTap: () => context.go('/customer/products/${product.productId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: CustomerColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomerColors.border),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: CustomerColors.surfaceSecondary,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        child: Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ProductPlaceholder()),
                      )
                    : const _ProductPlaceholder(),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName != null)
                      Text(product.categoryName!, style: const TextStyle(color: CustomerColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600, color: CustomerColors.textPrimary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(formatter.format(product.price), style: const TextStyle(color: CustomerColors.primary, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                        InkWell(
                          onTap: onAddToCart,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: CustomerColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFCBD5E1)));
  }
}
