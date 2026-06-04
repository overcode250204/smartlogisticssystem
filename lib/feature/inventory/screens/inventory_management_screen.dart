import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/create_supplier_dialog.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';
import 'package:smartlogisticssystem/feature/product/screens/create_product_dialog.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final InventoryService _service = InventoryService();
  late Future<InventoryDashboardData> _future;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDashboardData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      _future = _service.fetchDashboardData();
    });
  }

  Future<void> _openCreateProductDialog() async {
    final product = await showDialog<ProductResponse>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateProductDialog(),
    );

    if (product == null || !mounted) return;

    _reloadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo sản phẩm ${product.productName}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showBatchHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng tạo sản phẩm trước, sau đó tạo lô hàng.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InventoryDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể kết nối đến máy chủ backend',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chi tiết lỗi: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _reloadData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null ||
            (data.products.isEmpty &&
                data.batches.isEmpty &&
                data.transactions.isEmpty)) {
          return _EmptyInventoryState(
            onCreateProduct: _openCreateProductDialog,
            onCreateBatch: _showBatchHint,
            onReload: _reloadData,
          );
        }

        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsGrid(data: data),
              const SizedBox(height: 22),
              _InventoryTabs(
                data: data,
                searchController: _searchController,
                searchQuery: _searchQuery,
                onCreateProduct: _openCreateProductDialog,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  final VoidCallback onCreateProduct;
  final VoidCallback onCreateBatch;
  final VoidCallback onReload;

  const _EmptyInventoryState({
    required this.onCreateProduct,
    required this.onCreateBatch,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: DashboardCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Không có dữ liệu kho',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bắt đầu bằng cách tạo sản phẩm. Nếu chưa có nhà cung cấp, form sẽ cho phép tạo nhanh và tự chọn nhà cung cấp mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onCreateProduct,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tạo sản phẩm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCreateBatch,
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Tạo lô hàng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onReload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final InventoryDashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final lowStockCount = data.batches
        .where((b) {
          final p = data.products.where((p) => p.productId == b.product?.productId).firstOrNull;
          return b.remainingQuantity <= (p?.minStockLevel ?? 0);
        })
        .length;

    final cards = [
      StatCard(
        title: 'Tổng sản phẩm',
        value: data.products.length.toString(),
        subtitle: 'Sản phẩm',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      StatCard(
        title: 'Tổng lô hàng',
        value: data.batches.length.toString(),
        subtitle: 'Lô hàng',
        icon: Icons.all_inbox_outlined,
        color: AppColors.success,
      ),
      StatCard(
        title: 'Sắp hết hàng',
        value: lowStockCount.toString(),
        subtitle: 'Sản phẩm',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 900 ? 1 : 3;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 4.5 : 2.2,
          children: cards,
        );
      },
    );
  }
}

class _InventoryTabs extends StatelessWidget {
  final InventoryDashboardData data;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onCreateProduct;

  const _InventoryTabs({
    required this.data,
    required this.searchController,
    required this.searchQuery,
    required this.onCreateProduct,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: DashboardCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Sản phẩm', icon: Icon(Icons.inventory_2_outlined)),
                Tab(text: 'Lô hàng', icon: Icon(Icons.all_inbox_outlined)),
                Tab(
                  text: 'Giao dịch kho',
                  icon: Icon(Icons.receipt_long_outlined),
                ),
              ],
            ),
            SizedBox(
              height: 760,
              child: TabBarView(
                children: [
                  _ProductsTab(
                    data: data,
                    searchController: searchController,
                    searchQuery: searchQuery,
                    onCreateProduct: onCreateProduct,
                  ),
                  _BatchesTab(batches: data.batches),
                  _TransactionsTab(transactions: data.transactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final InventoryDashboardData data;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onCreateProduct;

  const _ProductsTab({
    required this.data,
    required this.searchController,
    required this.searchQuery,
    required this.onCreateProduct,
  });

  @override
  Widget build(BuildContext context) {
    final filteredProducts = data.products
        .where(
          (product) =>
              product.productName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              product.productCode.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (product.supplier?.supplierName ?? "").toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tìm kiếm sản phẩm hoặc mã...',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: onCreateProduct,
                icon: const Icon(Icons.add),
                label: const Text('Thêm sản phẩm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DarkTable(
            columns: const [
              DataColumn(label: Text('Mã SP')),
              DataColumn(label: Text('Tên SP')),
              DataColumn(label: Text('Nhà cung cấp')),
              DataColumn(label: Text('Tồn tối thiểu')),
              DataColumn(label: Text('Giá (VNĐ)')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: filteredProducts.map(_productRow).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hiển thị ${filteredProducts.length} của ${data.products.length} sản phẩm',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const _PageButton(label: '1', active: true),
            ],
          ),
          const SizedBox(height: 18),
          _BottomGrid(data: data),
        ],
      ),
    );
  }

  DataRow _productRow(ProductResponse product) {
    return DataRow(
      cells: [
        DataCell(Text(product.productCode)),
        DataCell(Text(product.productName)),
        DataCell(Text(product.supplier?.supplierName ?? "")),
        DataCell(Text(product.minStockLevel.toString())),
        DataCell(Text(currencyFormatter.format(product.price))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Sửa',
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatchesTab extends StatelessWidget {
  final List<InventoryBatchResponse> batches;

  const _BatchesTab({required this.batches});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: DarkTable(
        columns: const [
          DataColumn(label: Text('Mã lô')),
          DataColumn(label: Text('Sản phẩm')),
          DataColumn(label: Text('Ngày nhập')),
          DataColumn(label: Text('Hạn dùng')),
          DataColumn(label: Text('Số lượng')),
          DataColumn(label: Text('Còn lại')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: batches
            .map(
              (batch) => DataRow(
                cells: [
                  DataCell(Text('LH${batch.batchId ?? ''}')),
                  DataCell(Text((batch.product?.productName ?? "") ?? '')),
                  DataCell(Text(dateFormatter.format(batch.importDate))),
                  DataCell(Text(dateFormatter.format(batch.expirationDate))),
                  DataCell(Text(batch.quantity.toString())),
                  DataCell(Text(batch.remainingQuantity.toString())),
                  DataCell(StatusPill.batch(batch.status)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final List<InventoryTransactionResponse> transactions;

  const _TransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: DarkTable(
        columns: const [
          DataColumn(label: Text('Mã GD')),
          DataColumn(label: Text('Mã lô')),
          DataColumn(label: Text('Loại giao dịch')),
          DataColumn(label: Text('Số lượng')),
          DataColumn(label: Text('Ngày tạo')),
        ],
        rows: transactions
            .map(
              (transaction) => DataRow(
                cells: [
                  DataCell(Text('GD${transaction.transactionId ?? ''}')),
                  DataCell(Text('LH${transaction.batch?.batchId ?? ''}')),
                  DataCell(StatusPill.transaction(transaction.type)),
                  DataCell(Text(transaction.quantity.toString())),
                  DataCell(
                    Text(dateTimeFormatter.format(transaction.createdAt)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BottomGrid extends StatelessWidget {
  final InventoryDashboardData data;

  const _BottomGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fifteenDaysFromNow = now.add(const Duration(days: 15));

    final upcomingExpiringBatches = data.batches.where((b) {
      return b.expirationDate.isBefore(fifteenDaysFromNow);
    }).toList()
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

    final lowBatches = upcomingExpiringBatches.take(3).toList();
    final transactions = data.transactions.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 850;
        final children = [
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Lô hàng sắp hết hạn'),
                const SizedBox(height: 12),
                ...lowBatches.map(
                  (batch) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text((batch.product?.productName ?? "") ?? ''),
                    subtitle: Text(
                      'Hạn dùng ${dateFormatter.format(batch.expirationDate)}',
                    ),
                    trailing: StatusPill.batch(batch.status),
                  ),
                ),
              ],
            ),
          ),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Giao dịch mới nhất'),
                const SizedBox(height: 12),
                ...transactions.map(
                  (transaction) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('GD${transaction.transactionId ?? ''}'),
                    subtitle: Text(
                      dateTimeFormatter.format(transaction.createdAt),
                    ),
                    trailing: StatusPill.transaction(transaction.type),
                  ),
                ),
              ],
            ),
          ),
        ];

        if (narrow) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool active;

  const _PageButton({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(left: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.darkest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
