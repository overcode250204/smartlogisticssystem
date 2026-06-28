import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/feature/category/service/category_service.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/supplier/service/supplier_service.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _supplierService = SupplierService();
  final _searchController = TextEditingController();

  Timer? _debounceTimer;
  ProductPageResponse? _productPage;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;

  int _page = 0;
  int _size = 10;
  String? _keyword;
  int? _selectedCategoryId;
  int? _selectedSupplierId;

  List<ProductCategoryResponse> _categories = const [];
  List<SupplierResponse> _suppliers = const [];
  bool _isLoadingFilters = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadProducts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);
    try {
      final categoriesFuture = _categoryService.getAllCategories();
      final suppliersFuture = _supplierService.getAllSuppliers();
      final categories = await categoriesFuture;
      final suppliers = await suppliersFuture;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _isLoadingFilters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFilters = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu bộ lọc'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _loadProducts() async {
    final currentRequest = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _productService.getProductsPage(
        page: _page,
        size: _size,
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        supplierId: _selectedSupplierId,
      );
      if (!mounted || currentRequest != _requestId) return;
      setState(() {
        _productPage = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || currentRequest != _requestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách sản phẩm: $e';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      final nextKeyword = value.trim();
      if (!mounted || _keyword == nextKeyword) return;
      setState(() {
        _keyword = nextKeyword.isEmpty ? null : nextKeyword;
        _page = 0;
      });
      _loadProducts();
    });
  }

  void _onFilterChanged() {
    setState(() => _page = 0);
    _loadProducts();
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    setState(() {
      _searchController.clear();
      _keyword = null;
      _selectedCategoryId = null;
      _selectedSupplierId = null;
      _page = 0;
    });
    _loadProducts();
  }

  void _onPageChanged(int newPage) {
    final productPage = _productPage;
    if (newPage < 0 || (productPage != null && newPage >= productPage.totalPages)) {
      return;
    }
    setState(() => _page = newPage);
    _loadProducts();
  }

  void _onSizeChanged(int newSize) {
    setState(() {
      _size = newSize;
      _page = 0;
    });
    _loadProducts();
  }

  Future<void> _deleteProduct(ProductResponse product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.productName}" (${product.productCode}) không?',
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

      final currentPage = _productPage;
      if (currentPage != null && currentPage.content.length == 1 && _page > 0) {
        setState(() => _page -= 1);
      }
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa sản phẩm thất bại: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productPage = _productPage;

    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (productPage != null) ...[
                _buildSummaryCards(productPage),
                const SizedBox(height: 20),
              ],
              _buildFilters(),
              const SizedBox(height: 20),
              Expanded(child: _buildTableArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              width: compact ? constraints.maxWidth : constraints.maxWidth - 250,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard > Quản lý sản phẩm',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quản lý sản phẩm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Theo dõi và quản lý toàn bộ sản phẩm trong kho.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => context.go('/products/create'),
              icon: const Icon(Icons.add),
              label: const Text(
                'Tạo sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(ProductPageResponse data) {
    final currentVisiblePrice = data.content.fold<double>(
      0,
      (sum, product) => sum + product.price,
    );
    final lowStockCount = data.content
        .where((product) => product.minStockLevel != null && product.minStockLevel! <= 10)
        .length;
    final distinctSuppliers = data.content
        .where((product) => product.supplier?.supplierId != null)
        .map((product) => product.supplier!.supplierId)
        .toSet()
        .length;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 900
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _SummaryCard(
              width: cardWidth,
              title: 'Tổng sản phẩm',
              value: '${data.totalElements}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Tổng giá trị hiển thị',
              subtitle: 'Trang hiện tại',
              value: formatter.format(currentVisiblePrice),
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Sắp hết hàng',
              subtitle: 'Tồn tối thiểu <= 10',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Nhà cung cấp',
              subtitle: 'Trang hiện tại',
              value: '$distinctSuppliers',
              icon: Icons.business_outlined,
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    final hasActiveFilter = (_keyword?.isNotEmpty ?? false) ||
        _selectedCategoryId != null ||
        _selectedSupplierId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final fieldWidth = compact ? constraints.maxWidth : 300.0;
          final dropdownWidth = compact ? constraints.maxWidth : 220.0;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên, mã sản phẩm hoặc SKU',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(
                width: dropdownWidth,
                child: DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Danh mục',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả danh mục'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.categoryId,
                        child: Text(
                          category.categoryName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _isLoadingFilters
                      ? null
                      : (value) {
                          setState(() => _selectedCategoryId = value);
                          _onFilterChanged();
                        },
                ),
              ),
              SizedBox(
                width: dropdownWidth,
                child: DropdownButtonFormField<int?>(
                  value: _selectedSupplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Nhà cung cấp',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả NCC'),
                    ),
                    ..._suppliers.map(
                      (supplier) => DropdownMenuItem<int?>(
                        value: supplier.supplierId,
                        child: Text(
                          supplier.supplierName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _isLoadingFilters
                      ? null
                      : (value) {
                          setState(() => _selectedSupplierId = value);
                          _onFilterChanged();
                        },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
              if (hasActiveFilter)
                IconButton(
                  tooltip: 'Xóa bộ lọc',
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, color: AppColors.danger),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableArea() {
    if (_isLoading && _productPage == null) {
      return const _TableLoadingState();
    }

    if (_errorMessage != null) {
      return _TableErrorState(
        message: _errorMessage!,
        onRetry: _loadProducts,
      );
    }

    final pageData = _productPage;
    if (pageData == null) {
      return const SizedBox.shrink();
    }

    if (pageData.content.isEmpty) {
      return _EmptyProductState(
        onCreateProduct: () => context.go('/products/create'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildDataTable(pageData.content),
                if (_isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x99FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          _buildPagination(pageData),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<ProductResponse> products) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            dataRowMaxHeight: 64,
            dataRowMinHeight: 64,
            columns: const [
              DataColumn(label: Text('Ảnh')),
              DataColumn(label: Text('Mã SP')),
              DataColumn(label: Text('Tên sản phẩm')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Danh mục')),
              DataColumn(label: Text('Nhà cung cấp')),
              DataColumn(label: Text('Giá')),
              DataColumn(label: Text('Đơn vị')),
              DataColumn(label: Text('Tồn tối thiểu')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(_ProductImage(url: product.imageUrl)),
                  DataCell(_textCell(_fallback(product.productCode), width: 110)),
                  DataCell(
                    _textCell(
                      _fallback(product.productName),
                      width: 220,
                      maxLines: 2,
                      isStrong: true,
                    ),
                  ),
                  DataCell(_textCell(_fallback(product.sku), width: 120)),
                  DataCell(_textCell(_fallback(product.categoryName), width: 150)),
                  DataCell(_textCell(_fallback(product.supplier?.supplierName), width: 170)),
                  DataCell(
                    _textCell(
                      formatter.format(product.price),
                      width: 130,
                      color: AppColors.primary,
                      isStrong: true,
                    ),
                  ),
                  DataCell(_textCell(_unitLabel(product), width: 90)),
                  DataCell(_textCell(product.minStockLevel?.toString() ?? '—', width: 110)),
                  DataCell(_buildActions(product)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ProductResponse product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, color: AppColors.info),
          onPressed: () => context.go('/products/${product.productId}'),
          tooltip: 'Xem chi tiết',
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.warning),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chức năng chỉnh sửa đang được phát triển'),
              ),
            );
          },
          tooltip: 'Chỉnh sửa',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _deleteProduct(product),
          tooltip: 'Xóa',
        ),
      ],
    );
  }

  Widget _buildPagination(ProductPageResponse data) {
    final totalPages = data.totalPages > 0 ? data.totalPages : 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hiển thị: '),
              DropdownButton<int>(
                value: _size,
                underline: const SizedBox.shrink(),
                items: [10, 20, 50]
                    .map((size) => DropdownMenuItem(value: size, child: Text('$size')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _onSizeChanged(value);
                },
              ),
              const SizedBox(width: 8),
              Text('trên tổng số ${data.totalElements} sản phẩm'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trang ${data.page + 1} / $totalPages'),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: data.first ? null : () => _onPageChanged(data.page - 1),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Trước'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: data.last ? null : () => _onPageChanged(data.page + 1),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Sau'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
  }

  static String _unitLabel(ProductResponse product) {
    final unitCode = product.baseUnitCode?.trim();
    if (unitCode != null && unitCode.isNotEmpty) return unitCode;
    return _fallback(product.baseUnitName);
  }

  static Widget _textCell(
    String text, {
    required double width,
    int maxLines = 1,
    bool isStrong = false,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: isStrong ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableLoadingState extends StatelessWidget {
  const _TableLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _TableErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TableErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _EmptyProductState extends StatelessWidget {
  final VoidCallback onCreateProduct;

  const _EmptyProductState({required this.onCreateProduct});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có sản phẩm phù hợp',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreateProduct,
            icon: const Icon(Icons.add),
            label: const Text('Tạo sản phẩm'),
          ),
        ],
      ),
    );
  }
}
