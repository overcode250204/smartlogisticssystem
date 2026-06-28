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

  bool _isLoading = false;
  String? _error;

  ProductPageResponse? _pageData;
  int _page = 0;
  int _size = 10;
  String? _keyword;
  int? _selectedCategoryId;
  int? _selectedSupplierId;

  List<ProductCategoryResponse> _categories = [];
  List<SupplierResponse> _suppliers = [];
  bool _filtersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFiltersAndData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFiltersAndData() async {
    try {
      final futures = await Future.wait([
        _categoryService.getAllCategories(),
        _supplierService.getAllSuppliers(),
      ]);
      if (mounted) {
        setState(() {
          _categories = futures[0] as List<ProductCategoryResponse>;
          _suppliers = futures[1] as List<SupplierResponse>;
          _filtersLoaded = true;
        });
        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi khi tải dữ liệu bộ lọc: $e';
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _productService.getProductsPage(
        page: _page,
        size: _size,
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        supplierId: _selectedSupplierId,
      );
      if (mounted) {
        setState(() {
          _pageData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Lỗi khi tải danh sách sản phẩm: $e';
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _keyword != value) {
        setState(() {
          _keyword = value;
          _page = 0;
        });
        _fetchProducts();
      }
    });
  }

  void _onFilterChanged() {
    setState(() {
      _page = 0;
    });
    _fetchProducts();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _keyword = null;
      _selectedCategoryId = null;
      _selectedSupplierId = null;
      _page = 0;
    });
    _fetchProducts();
  }

  void _onPageChanged(int newPage) {
    if (newPage < 0 || (_pageData != null && newPage >= _pageData!.totalPages)) {
      return;
    }
    setState(() {
      _page = newPage;
    });
    _fetchProducts();
  }

  void _onSizeChanged(int newSize) {
    setState(() {
      _size = newSize;
      _page = 0;
    });
    _fetchProducts();
  }

  Future<void> _deleteProduct(ProductResponse product) async {
    final confirm = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(product.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa sản phẩm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          
          if (_pageData != null && _pageData!.content.length == 1 && _page > 0) {
            _page--;
          }
          _fetchProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xóa thất bại: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_pageData != null) _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            Expanded(child: _buildTableArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard > Quản lý sản phẩm',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý sản phẩm',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Theo dõi và quản lý toàn bộ sản phẩm trong kho.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => context.go('/products/create'),
          icon: const Icon(Icons.add),
          label: const Text('+ Tạo sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final data = _pageData!;
    
    final totalElements = data.totalElements;
    
    final currentVisiblePrice = data.content.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    
    final lowStockCount = data.content.where((p) => p.minStockLevel <= 10).length;
    
    final distinctSuppliers = data.content
        .where((p) => p.supplier != null)
        .map((p) => p.supplier!.supplierId)
        .toSet()
        .length;

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Tổng sản phẩm',
            value: '$totalElements',
            icon: Icons.inventory_2_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Tổng giá trị hiển thị',
            subtitle: 'Trang hiện tại',
            value: formatter.format(currentVisiblePrice),
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Sắp hết hàng',
            subtitle: 'Tồn kho ≤ 10',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Nhà cung cấp',
            subtitle: 'Trang hiện tại',
            value: '$distinctSuppliers',
            icon: Icons.business_outlined,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final hasActiveFilter = (_keyword != null && _keyword!.isNotEmpty) ||
        _selectedCategoryId != null ||
        _selectedSupplierId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, mã sản phẩm hoặc SKU',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                hintText: 'Danh mục',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả danh mục')),
                ..._categories.map((c) => DropdownMenuItem(
                      value: c.categoryId,
                      child: Text(c.categoryName),
                    )),
              ],
              onChanged: (val) {
                _selectedCategoryId = val;
                _onFilterChanged();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _selectedSupplierId,
              decoration: InputDecoration(
                hintText: 'Nhà cung cấp',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả NCC')),
                ..._suppliers.map((s) => DropdownMenuItem(
                      value: s.supplierId,
                      child: Text(s.supplierName),
                    )),
              ],
              onChanged: (val) {
                _selectedSupplierId = val;
                _onFilterChanged();
              },
            ),
          ),
          const SizedBox(width: 16),
          if (hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.danger),
              tooltip: 'Làm mới',
              onPressed: _clearFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildTableArea() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProducts, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_isLoading && _pageData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pageData != null && _pageData!.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Chưa có sản phẩm phù hợp',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/products/create'),
              child: const Text('Tạo sản phẩm'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: _buildDataTable(),
                  ),
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white54,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return DataTable(
      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
      rows: _pageData!.content.map((product) {
        return DataRow(
          cells: [
            DataCell(
              product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 40),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.grey),
                    ),
            ),
            DataCell(Text(product.productCode, maxLines: 1, overflow: TextOverflow.ellipsis)),
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            DataCell(Text(product.sku.isNotEmpty ? product.sku : '—')),
            DataCell(Text(product.categoryName ?? '—')),
            DataCell(Text(product.supplier?.supplierName ?? '—')),
            DataCell(Text(formatter.format(product.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
            DataCell(Text(product.baseUnitCode ?? product.baseUnitName ?? '—')),
            DataCell(Text('${product.minStockLevel}')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    onPressed: () => context.go('/products/${product.productId}'),
                    tooltip: 'Xem chi tiết',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng chỉnh sửa đang được phát triển')),
                      );
                    },
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    onPressed: () => _deleteProduct(product),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPagination() {
    if (_pageData == null) return const SizedBox.shrink();

    final data = _pageData!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Hiển thị: '),
              DropdownButton<int>(
                value: _size,
                underline: const SizedBox.shrink(),
                items: [10, 20, 50].map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
                onChanged: (val) {
                  if (val != null) _onSizeChanged(val);
                },
              ),
              const SizedBox(width: 8),
              Text('trên tổng số ${data.totalElements} sản phẩm'),
            ],
          ),
          Row(
            children: [
              Text('Trang ${data.page + 1} / ${data.totalPages > 0 ? data.totalPages : 1}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: data.first ? null : () => _onPageChanged(data.page - 1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: data.last ? null : () => _onPageChanged(data.page + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
