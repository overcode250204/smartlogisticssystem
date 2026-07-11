import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_request_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/feature/category/service/category_service.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/supplier/service/supplier_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';

enum StockFilter { all, inStock, lowStock, outOfStock }

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _supplierService = SupplierService();
  final _batchService = InventoryBatchService();

  final _searchController = TextEditingController();
  final _supplierSectionKey = GlobalKey();
  final _categorySectionKey = GlobalKey();

  Timer? _debounceTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  List<ProductResponse> _products = const [];
  List<ProductCategoryResponse> _categories = const [];
  List<SupplierResponse> _suppliers = const [];
  List<InventoryBatchResponse> _batches = const [];

  String? _keyword;
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  StockFilter _stockFilter = StockFilter.all;
  int _page = 0;
  int _size = 10;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool refresh = false}) async {
    setState(() {
      _isLoading = !refresh;
      _isRefreshing = refresh;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _categoryService.getAllCategories(),
        _supplierService.getAllSuppliers(),
        _batchService.getAllBatches(),
      ]);

      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProductResponse>;
        _categories = results[1] as List<ProductCategoryResponse>;
        _suppliers = results[2] as List<SupplierResponse>;
        _batches = results[3] as List<InventoryBatchResponse>;
        _isLoading = false;
        _isRefreshing = false;
        _page = _page.clamp(0, _lastPage(_filteredProducts.length));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Không thể tải dữ liệu dashboard: ${apiErrorMessage(error)}';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshProductsOnly() async {
    setState(() => _isRefreshing = true);
    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _batchService.getAllBatches(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProductResponse>;
        _batches = results[1] as List<InventoryBatchResponse>;
        _isRefreshing = false;
        _page = _page.clamp(0, _lastPage(_filteredProducts.length));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showSnack(
        'Không thể làm mới sản phẩm: ${apiErrorMessage(error)}',
        AppColors.danger,
      );
    }
  }

  Future<void> _refreshSuppliersOnly() async {
    final suppliers = await _supplierService.getAllSuppliers();
    if (!mounted) return;
    setState(() => _suppliers = suppliers);
  }

  Future<void> _refreshCategoriesOnly() async {
    final categories = await _categoryService.getAllCategories();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _keyword = value.trim().isEmpty ? null : value.trim().toLowerCase();
        _page = 0;
      });
    });
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    setState(() {
      _searchController.clear();
      _keyword = null;
      _selectedCategoryId = null;
      _selectedSupplierId = null;
      _stockFilter = StockFilter.all;
      _page = 0;
    });
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
      _showSnack('Xóa sản phẩm thành công', AppColors.success);
      await _refreshProductsOnly();
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'Xóa sản phẩm thất bại: ${apiErrorMessage(error)}',
        AppColors.danger,
      );
    }
  }

  Future<void> _deleteSupplier(SupplierResponse supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa nhà cung cấp "${supplier.supplierName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _supplierService.deleteSupplier(supplier.supplierId);
      if (!mounted) return;
      _showSnack('Xóa nhà cung cấp thành công', AppColors.success);
      await _refreshSuppliersOnly();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Lỗi: ${apiErrorMessage(error)}', AppColors.danger);
    }
  }

  Future<void> _deleteCategory(ProductCategoryResponse category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.categoryName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final deleted = await _categoryService.deleteCategory(
        category.categoryId,
      );
      if (!mounted) return;
      if (deleted) {
        _showSnack('Xóa danh mục thành công', AppColors.success);
        await _refreshCategoriesOnly();
      } else {
        _showSnack('Không thể xóa danh mục', AppColors.danger);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack('Lỗi: ${apiErrorMessage(error)}', AppColors.danger);
    }
  }

  Future<void> _showSupplierQuickCreate([SupplierResponse? supplier]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SupplierQuickCreateDialog(
        supplier: supplier,
        supplierService: _supplierService,
      ),
    );
    if (changed == true) {
      await _refreshSuppliersOnly();
      _showSnack(
        supplier == null
            ? 'Thêm nhà cung cấp thành công'
            : 'Cập nhật nhà cung cấp thành công',
        AppColors.success,
      );
    }
  }

  Future<void> _showCategoryQuickCreate([
    ProductCategoryResponse? category,
  ]) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryQuickCreateDialog(
        category: category,
        categoryService: _categoryService,
      ),
    );
    if (changed == true) {
      await _refreshCategoriesOnly();
      _showSnack(
        category == null
            ? 'Thêm danh mục thành công'
            : 'Cập nhật danh mục thành công',
        AppColors.success,
      );
    }
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Map<int, int> get _stockByProductId {
    final totals = <int, int>{};
    for (final batch in _batches) {
      final productId = batch.product?.productId;
      if (productId == null) continue;
      totals[productId] = (totals[productId] ?? 0) + batch.remainingQuantity;
    }
    return totals;
  }

  List<ProductResponse> get _filteredProducts {
    final stockMap = _stockByProductId;
    return _products.where((product) {
      final keyword = _keyword;
      if (keyword != null) {
        final searchable = [
          product.productName,
          product.productCode,
          product.sku,
        ].join(' ').toLowerCase();
        if (!searchable.contains(keyword)) {
          return false;
        }
      }
      if (_selectedCategoryId != null &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedSupplierId != null &&
          product.supplier?.supplierId != _selectedSupplierId) {
        return false;
      }
      return _matchesStockFilter(product, stockMap[product.productId]);
    }).toList();
  }

  bool _matchesStockFilter(ProductResponse product, int? stock) {
    final min = product.minStockLevel;
    switch (_stockFilter) {
      case StockFilter.all:
        return true;
      case StockFilter.inStock:
        if (stock == null || min == null) return false;
        return stock > min;
      case StockFilter.lowStock:
        if (stock == null || min == null) return false;
        return stock > 0 && stock <= min;
      case StockFilter.outOfStock:
        if (stock == null) return false;
        return stock <= 0;
    }
  }

  int _lastPage(int totalItems) {
    if (totalItems <= 0) return 0;
    return ((totalItems - 1) / _size).floor();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _products.isEmpty) {
      return _DashboardErrorState(
        message: _errorMessage!,
        onRetry: () => _loadDashboard(),
      );
    }

    final filteredProducts = _filteredProducts;
    final lastPage = _lastPage(filteredProducts.length);
    if (_page > lastPage) _page = lastPage;
    final pagedProducts = filteredProducts
        .skip(_page * _size)
        .take(_size)
        .toList();
    final stockMap = _stockByProductId;

    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboard(refresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardActionBar(
                      onCreateProduct: () => context.go('/products/create'),
                      onCreateSupplier: () => _showSupplierQuickCreate(),
                      onCreateCategory: () => _showCategoryQuickCreate(),
                    ),
                    const SizedBox(height: 20),
                    ProductOverviewKpiSection(
                      products: _products,
                      suppliers: _suppliers,
                      categories: _categories,
                      batches: _batches,
                      stockByProductId: stockMap,
                      onLowStockTap: () {
                        setState(() {
                          _stockFilter = StockFilter.lowStock;
                          _page = 0;
                        });
                      },
                      onSupplierTap: () => _scrollTo(_supplierSectionKey),
                      onCategoryTap: () => _scrollTo(_categorySectionKey),
                    ),
                    const SizedBox(height: 20),
                    ProductFilterBar(
                      searchController: _searchController,
                      categories: _categories,
                      suppliers: _suppliers,
                      selectedCategoryId: _selectedCategoryId,
                      selectedSupplierId: _selectedSupplierId,
                      stockFilter: _stockFilter,
                      isRefreshing: _isRefreshing,
                      hasActiveFilter:
                          _keyword != null ||
                          _selectedCategoryId != null ||
                          _selectedSupplierId != null ||
                          _stockFilter != StockFilter.all,
                      onSearchChanged: _onSearchChanged,
                      onCategoryChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _page = 0;
                        });
                      },
                      onSupplierChanged: (value) {
                        setState(() {
                          _selectedSupplierId = value;
                          _page = 0;
                        });
                      },
                      onStockFilterChanged: (value) {
                        setState(() {
                          _stockFilter = value;
                          _page = 0;
                        });
                      },
                      onRefresh: () => _loadDashboard(refresh: true),
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 20),
                    ProductDataTable(
                      products: pagedProducts,
                      totalItems: filteredProducts.length,
                      page: _page,
                      size: _size,
                      stockByProductId: stockMap,
                      isRefreshing: _isRefreshing,
                      onCreateProduct: () => context.go('/products/create'),
                      onView: (product) =>
                          context.go('/products/${product.productId}'),
                      onEdit: (product) =>
                          context.go('/products/${product.productId}/edit'),
                      onDelete: _deleteProduct,
                      onCategoryTap: (categoryId) {
                        setState(() {
                          _selectedCategoryId = categoryId;
                          _page = 0;
                        });
                      },
                      onSupplierTap: (supplierId) {
                        setState(() {
                          _selectedSupplierId = supplierId;
                          _page = 0;
                        });
                      },
                      onPageChanged: (page) => setState(() => _page = page),
                      onSizeChanged: (size) {
                        setState(() {
                          _size = size;
                          _page = 0;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stack = constraints.maxWidth < 980;
                        final supplierCard = SupplierOverviewCard(
                          key: _supplierSectionKey,
                          suppliers: _suppliers,
                          productCounts: _supplierProductCounts,
                          onAdd: () => _showSupplierQuickCreate(),
                          onViewAll: () => context.go('/suppliers'),
                          onEdit: _showSupplierQuickCreate,
                          onDelete: _deleteSupplier,
                        );
                        final categoryCard = CategoryOverviewCard(
                          key: _categorySectionKey,
                          categories: _categories,
                          productCounts: _categoryProductCounts,
                          onAdd: () => _showCategoryQuickCreate(),
                          onViewAll: () => context.go('/categories'),
                          onEdit: _showCategoryQuickCreate,
                          onDelete: _deleteCategory,
                        );
                        if (stack) {
                          return Column(
                            children: [
                              supplierCard,
                              const SizedBox(height: 20),
                              categoryCard,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: supplierCard),
                            const SizedBox(width: 20),
                            Expanded(child: categoryCard),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, int> get _supplierProductCounts {
    final counts = <int, int>{};
    for (final product in _products) {
      final supplierId = product.supplier?.supplierId;
      if (supplierId == null) continue;
      counts[supplierId] = (counts[supplierId] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, int> get _categoryProductCounts {
    final counts = <int, int>{};
    for (final product in _products) {
      final categoryId = product.categoryId;
      if (categoryId == null) continue;
      counts[categoryId] = (counts[categoryId] ?? 0) + 1;
    }
    return counts;
  }
}

class DashboardActionBar extends StatelessWidget {
  final VoidCallback onCreateProduct;
  final VoidCallback onCreateSupplier;
  final VoidCallback onCreateCategory;

  const DashboardActionBar({
    super.key,
    required this.onCreateProduct,
    required this.onCreateSupplier,
    required this.onCreateCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 680),
          child: Column(
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
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Theo dõi sản phẩm, nhà cung cấp và danh mục trong cùng một nơi.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onCreateSupplier,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Thêm nhà cung cấp'),
            ),
            OutlinedButton.icon(
              onPressed: onCreateCategory,
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Thêm danh mục'),
            ),
            ElevatedButton.icon(
              onPressed: onCreateProduct,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo sản phẩm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductOverviewKpiSection extends StatelessWidget {
  final List<ProductResponse> products;
  final List<SupplierResponse> suppliers;
  final List<ProductCategoryResponse> categories;
  final List<InventoryBatchResponse> batches;
  final Map<int, int> stockByProductId;
  final VoidCallback onLowStockTap;
  final VoidCallback onSupplierTap;
  final VoidCallback onCategoryTap;

  const ProductOverviewKpiSection({
    super.key,
    required this.products,
    required this.suppliers,
    required this.categories,
    required this.batches,
    required this.stockByProductId,
    required this.onLowStockTap,
    required this.onSupplierTap,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((product) {
      final stock = stockByProductId[product.productId];
      final min = product.minStockLevel;
      if (stock == null || min == null) return false;
      return stock > 0 && stock <= min;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 5
            : constraints.maxWidth >= 860
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              width: width,
              title: 'Tổng sản phẩm',
              value: '${products.length}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            _KpiCard(
              width: width,
              title: 'Lô tồn kho',
              value: '${batches.length}',
              icon: Icons.qr_code_2_outlined,
              color: AppColors.success,
            ),
            _KpiCard(
              width: width,
              title: 'Sắp hết hàng',
              value: '$lowStock',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              onTap: onLowStockTap,
            ),
            _KpiCard(
              width: width,
              title: 'Nhà cung cấp',
              value: '${suppliers.length}',
              icon: Icons.business_outlined,
              color: AppColors.primary,
              onTap: onSupplierTap,
            ),
            _KpiCard(
              width: width,
              title: 'Danh mục',
              value: '${categories.length}',
              icon: Icons.category_outlined,
              color: AppColors.primary,
              onTap: onCategoryTap,
            ),
          ],
        );
      },
    );
  }
}

class ProductFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final List<ProductCategoryResponse> categories;
  final List<SupplierResponse> suppliers;
  final int? selectedCategoryId;
  final int? selectedSupplierId;
  final StockFilter stockFilter;
  final bool isRefreshing;
  final bool hasActiveFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onSupplierChanged;
  final ValueChanged<StockFilter> onStockFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onClear;

  const ProductFilterBar({
    super.key,
    required this.searchController,
    required this.categories,
    required this.suppliers,
    required this.selectedCategoryId,
    required this.selectedSupplierId,
    required this.stockFilter,
    required this.isRefreshing,
    required this.hasActiveFilter,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSupplierChanged,
    required this.onStockFilterChanged,
    required this.onRefresh,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final searchWidth = compact ? constraints.maxWidth : 320.0;
          final filterWidth = compact ? constraints.maxWidth : 220.0;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên, mã sản phẩm hoặc SKU',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả danh mục'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem<int?>(
                        value: category.categoryId,
                        child: Text(
                          category.categoryName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedSupplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả NCC'),
                    ),
                    ...suppliers.map(
                      (supplier) => DropdownMenuItem<int?>(
                        value: supplier.supplierId,
                        child: Text(
                          supplier.supplierName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: onSupplierChanged,
                ),
              ),
              SizedBox(
                width: filterWidth,
                child: DropdownButtonFormField<StockFilter>(
                  initialValue: stockFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái tồn',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StockFilter.all,
                      child: Text('Tất cả'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.inStock,
                      child: Text('Còn hàng'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.lowStock,
                      child: Text('Sắp hết hàng'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.outOfStock,
                      child: Text('Hết hàng'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onStockFilterChanged(value);
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
              if (hasActiveFilter)
                IconButton(
                  tooltip: 'Xóa bộ lọc',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, color: AppColors.danger),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProductDataTable extends StatelessWidget {
  final List<ProductResponse> products;
  final int totalItems;
  final int page;
  final int size;
  final Map<int, int> stockByProductId;
  final bool isRefreshing;
  final VoidCallback onCreateProduct;
  final ValueChanged<ProductResponse> onView;
  final ValueChanged<ProductResponse> onEdit;
  final ValueChanged<ProductResponse> onDelete;
  final ValueChanged<int> onCategoryTap;
  final ValueChanged<int> onSupplierTap;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const ProductDataTable({
    super.key,
    required this.products,
    required this.totalItems,
    required this.page,
    required this.size,
    required this.stockByProductId,
    required this.isRefreshing,
    required this.onCreateProduct,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onCategoryTap,
    required this.onSupplierTap,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalPages = totalItems <= 0
        ? 1
        : ((totalItems - 1) / size).floor() + 1;
    final showImageColumn = products.any(
      (product) => product.imageUrl?.trim().isNotEmpty ?? false,
    );

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Expanded(child: _SectionTitle('Danh sách sản phẩm')),
                if (isRefreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (products.isEmpty)
            _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có sản phẩm phù hợp',
              message: 'Thử điều chỉnh bộ lọc hoặc tạo sản phẩm mới.',
              actionLabel: 'Tạo sản phẩm',
              onAction: onCreateProduct,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  AppColors.darkest.withValues(alpha: 0.9),
                ),
                dataRowMinHeight: 72,
                dataRowMaxHeight: 78,
                columnSpacing: 24,
                horizontalMargin: 20,
                columns: [
                  if (showImageColumn) const DataColumn(label: Text('Ảnh')),
                  const DataColumn(label: Text('Tên sản phẩm')),
                  const DataColumn(label: Text('Mã sản phẩm / SKU')),
                  const DataColumn(label: Text('Giá')),
                  const DataColumn(label: Text('Danh mục')),
                  const DataColumn(label: Text('Nhà cung cấp')),
                  const DataColumn(label: Text('Tồn kho')),
                  const DataColumn(label: Text('Trạng thái')),
                  const DataColumn(label: Text('Thao tác')),
                ],
                rows: products.map((product) {
                  final stock = stockByProductId[product.productId];
                  return DataRow(
                    onSelectChanged: (_) => onView(product),
                    cells: [
                      if (showImageColumn)
                        DataCell(
                          product.imageUrl?.trim().isNotEmpty ?? false
                              ? _ProductImage(url: product.imageUrl)
                              : const _MissingDataText(),
                        ),
                      DataCell(
                        _EllipsisText(
                          product.productName,
                          width: 220,
                          strong: true,
                        ),
                      ),
                      DataCell(
                        _TwoLineCell(
                          primary: _fallback(product.productCode),
                          secondary: product.sku.isEmpty
                              ? 'SKU: Chưa có dữ liệu'
                              : 'SKU: ${product.sku}',
                          width: 160,
                        ),
                      ),
                      DataCell(
                        _EllipsisText(
                          currency.format(product.price),
                          width: 120,
                          color: AppColors.primary,
                          strong: true,
                        ),
                      ),
                      DataCell(
                        product.categoryId == null
                            ? const _MissingDataText()
                            : _FilterChipButton(
                                label: _fallback(product.categoryName),
                                icon: Icons.category_outlined,
                                onTap: () => onCategoryTap(product.categoryId!),
                              ),
                      ),
                      DataCell(
                        product.supplier == null
                            ? const _MissingDataText()
                            : _FilterChipButton(
                                label: product.supplier!.supplierName,
                                icon: Icons.business_outlined,
                                onTap: () =>
                                    onSupplierTap(product.supplier!.supplierId),
                              ),
                      ),
                      DataCell(
                        stock == null
                            ? const _MissingDataText()
                            : _EllipsisText('$stock', width: 72, strong: true),
                      ),
                      DataCell(
                        _StockStatusChip(
                          stock: stock,
                          minStockLevel: product.minStockLevel,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Xem chi tiết',
                              onPressed: () => onView(product),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: AppColors.info,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Chỉnh sửa',
                              onPressed: () => onEdit(product),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa',
                              onPressed: () => onDelete(product),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          _PaginationBar(
            page: page,
            size: size,
            totalItems: totalItems,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
            onSizeChanged: onSizeChanged,
          ),
        ],
      ),
    );
  }
}

class SupplierOverviewCard extends StatelessWidget {
  final List<SupplierResponse> suppliers;
  final Map<int, int> productCounts;
  final VoidCallback onAdd;
  final VoidCallback onViewAll;
  final ValueChanged<SupplierResponse> onEdit;
  final ValueChanged<SupplierResponse> onDelete;

  const SupplierOverviewCard({
    super.key,
    required this.suppliers,
    required this.productCounts,
    required this.onAdd,
    required this.onViewAll,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visible = suppliers.take(6).toList();
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverviewHeader(
            title: 'Danh sách nhà cung cấp',
            actionLabel: 'Thêm nhà cung cấp',
            onAdd: onAdd,
            onViewAll: suppliers.length > 6 ? onViewAll : null,
          ),
          if (visible.isEmpty)
            const _CompactEmptyState(message: 'Chưa có nhà cung cấp')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 16,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Tên nhà cung cấp')),
                  DataColumn(label: Text('Số điện thoại')),
                  DataColumn(label: Text('Địa chỉ')),
                  DataColumn(label: Text('Số sản phẩm cung cấp')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: visible.map((supplier) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _EllipsisText(
                          supplier.supplierName,
                          width: 190,
                          strong: true,
                        ),
                      ),
                      DataCell(
                        _EllipsisText(
                          _fallback(supplier.contactPhone),
                          width: 120,
                        ),
                      ),
                      DataCell(
                        _EllipsisText(_fallback(supplier.address), width: 160),
                      ),
                      DataCell(
                        Text('${productCounts[supplier.supplierId] ?? 0}'),
                      ),
                      DataCell(
                        _OverviewActions(
                          onEdit: () => onEdit(supplier),
                          onDelete: () => onDelete(supplier),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryOverviewCard extends StatelessWidget {
  final List<ProductCategoryResponse> categories;
  final Map<int, int> productCounts;
  final VoidCallback onAdd;
  final VoidCallback onViewAll;
  final ValueChanged<ProductCategoryResponse> onEdit;
  final ValueChanged<ProductCategoryResponse> onDelete;

  const CategoryOverviewCard({
    super.key,
    required this.categories,
    required this.productCounts,
    required this.onAdd,
    required this.onViewAll,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visible = categories.take(6).toList();
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverviewHeader(
            title: 'Danh sách danh mục',
            actionLabel: 'Thêm danh mục',
            onAdd: onAdd,
            onViewAll: categories.length > 6 ? onViewAll : null,
          ),
          if (visible.isEmpty)
            const _CompactEmptyState(message: 'Chưa có danh mục')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 16,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Tên danh mục')),
                  DataColumn(label: Text('Mô tả')),
                  DataColumn(label: Text('Số sản phẩm')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: visible.map((category) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _EllipsisText(
                          category.categoryName,
                          width: 190,
                          strong: true,
                        ),
                      ),
                      DataCell(
                        _EllipsisText(
                          _fallback(category.description),
                          width: 160,
                        ),
                      ),
                      DataCell(
                        Text('${productCounts[category.categoryId] ?? 0}'),
                      ),
                      DataCell(
                        _OverviewActions(
                          onEdit: () => onEdit(category),
                          onDelete: () => onDelete(category),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class SupplierQuickCreateDialog extends StatefulWidget {
  final SupplierResponse? supplier;
  final SupplierService supplierService;

  const SupplierQuickCreateDialog({
    super.key,
    this.supplier,
    required this.supplierService,
  });

  @override
  State<SupplierQuickCreateDialog> createState() =>
      _SupplierQuickCreateDialogState();
}

class _SupplierQuickCreateDialogState extends State<SupplierQuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    if (supplier != null) {
      _nameController.text = supplier.supplierName;
      _phoneController.text = supplier.contactPhone ?? '';
      _addressController.text = supplier.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final supplier = widget.supplier;
      if (supplier == null) {
        await widget.supplierService.createSupplier(
          SupplierCreateRequest(
            supplierName: _nameController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          ),
        );
      } else {
        await widget.supplierService.updateSupplier(
          supplier.supplierId,
          SupplierUpdateRequest(
            supplierName: _nameController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialogShell(
      title: widget.supplier == null ? 'Thêm nhà cung cấp' : 'Sửa nhà cung cấp',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Tên nhà cung cấp *',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bắt buộc nhập'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final regex = RegExp(r'^\+?[0-9]{8,15}$');
                  if (!regex.hasMatch(value.trim())) {
                    return 'Số điện thoại không hợp lệ';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _DialogError(message: _errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryQuickCreateDialog extends StatefulWidget {
  final ProductCategoryResponse? category;
  final CategoryService categoryService;

  const CategoryQuickCreateDialog({
    super.key,
    this.category,
    required this.categoryService,
  });

  @override
  State<CategoryQuickCreateDialog> createState() =>
      _CategoryQuickCreateDialogState();
}

class _CategoryQuickCreateDialogState extends State<CategoryQuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _nameController.text = category.categoryName;
      _descriptionController.text = category.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final category = widget.category;
      final request = ProductCategoryCreateRequest(
        categoryCode:
            category?.categoryCode ??
            'CAT-${DateTime.now().millisecondsSinceEpoch}',
        categoryName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (category == null) {
        await widget.categoryService.createCategory(request);
      } else {
        final updated = await widget.categoryService.updateCategory(
          category.categoryId,
          request,
        );
        if (updated == null) throw Exception('Không thể cập nhật danh mục');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialogShell(
      title: widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bắt buộc nhập'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _DialogError(message: _errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _FormDialogShell({
    required this.title,
    required this.child,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _SectionTitle(title)),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(isSubmitting ? 'Đang lưu...' : 'Lưu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const _PaginationBar({
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                value: size,
                underline: const SizedBox.shrink(),
                items: [10, 20, 50]
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text('$item')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSizeChanged(value);
                },
              ),
              const SizedBox(width: 8),
              Text('trên tổng số $totalItems sản phẩm'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trang ${page + 1} / $totalPages'),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: page <= 0 ? null : () => onPageChanged(page - 1),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Trước'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: page >= totalPages - 1
                    ? null
                    : () => onPageChanged(page + 1),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Sau'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAdd;
  final VoidCallback? onViewAll;

  const _OverviewHeader({
    required this.title,
    required this.actionLabel,
    required this.onAdd,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SectionTitle(title),
          Wrap(
            spacing: 8,
            children: [
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Xem tất cả'),
                ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OverviewActions({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Chỉnh sửa',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
        ),
        IconButton(
          tooltip: 'Xóa',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockStatusChip extends StatelessWidget {
  final int? stock;
  final int? minStockLevel;

  const _StockStatusChip({required this.stock, required this.minStockLevel});

  @override
  Widget build(BuildContext context) {
    if (stock == null || minStockLevel == null) {
      return const _MissingDataText();
    }
    final currentStock = stock!;
    final minimumStock = minStockLevel!;
    if (currentStock <= 0) {
      return const _StatusChip(label: 'Hết hàng', color: AppColors.danger);
    }
    if (currentStock <= minimumStock) {
      return const _StatusChip(label: 'Sắp hết hàng', color: AppColors.warning);
    }
    return const _StatusChip(label: 'Còn hàng', color: AppColors.success);
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TwoLineCell extends StatelessWidget {
  final String primary;
  final String secondary;
  final double width;

  const _TwoLineCell({
    required this.primary,
    required this.secondary,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EllipsisText extends StatelessWidget {
  final String text;
  final double width;
  final bool strong;
  final Color? color;

  const _EllipsisText(
    this.text, {
    required this.width,
    this.strong = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: SizedBox(
        width: width,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          ),
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
    if (imageUrl.isEmpty) return const _MissingDataText();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _MissingDataText(),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DashboardCard({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  final String message;

  const _CompactEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  final String message;

  const _DialogError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _MissingDataText extends StatelessWidget {
  const _MissingDataText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Chưa có dữ liệu',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: AppColors.textSecondary),
    );
  }
}

String _fallback(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? 'Chưa có dữ liệu' : trimmed;
}
