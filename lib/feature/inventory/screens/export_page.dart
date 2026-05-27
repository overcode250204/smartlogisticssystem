import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_transaction_service.dart';
import 'package:smartlogisticssystem/feature/inventory/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final ProductService _productService = ProductService();
  final InventoryBatchService _batchService = InventoryBatchService();
  final InventoryTransactionService _transactionService =
      InventoryTransactionService();
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();

  List<ProductResponse> _products = [];
  List<InventoryBatchResponse> _batches = [];
  List<InventoryTransactionResponse> _transactions = [];
  ProductResponse? _selectedProduct;
  InventoryExportResponse? _lastExport;
  DateTime _exportDate = DateTime.now();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dateController.text = dateFormatter.format(_exportDate);
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<InventoryBatchResponse> get _availableBatches {
    final productId = _selectedProduct?.productId;
    if (productId == null) return [];

    return _batches
        .where(
          (batch) =>
              batch.product?.productId == productId && batch.remainingQuantity > 0,
        )
        .toList();
  }

  int get _availableStock {
    return _availableBatches.fold(
      0,
      (total, batch) => total + batch.remainingQuantity,
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _batchService.getAllBatches(),
        _transactionService.getAllTransactions(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<ProductResponse>;
        _batches = results[1] as List<InventoryBatchResponse>;
        _transactions = results[2] as List<InventoryTransactionResponse>;
        _syncSelectedProduct();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = apiErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadAfterExport() async {
    final results = await Future.wait([
      _batchService.getAllBatches(),
      _transactionService.getAllTransactions(),
    ]);

    if (!mounted) return;

    setState(() {
      _batches = results[0] as List<InventoryBatchResponse>;
      _transactions = results[1] as List<InventoryTransactionResponse>;
      _syncSelectedProduct();
    });
  }

  void _syncSelectedProduct() {
    final selectedProductId = _selectedProduct?.productId;
    if (selectedProductId != null) {
      _selectedProduct = _products
          .where((product) => product.productId == selectedProductId)
          .cast<ProductResponse?>()
          .firstWhere((product) => product != null, orElse: () => null);
    }
  }

  void _onProductChanged(ProductResponse? product) {
    setState(() {
      _selectedProduct = product;
      _lastExport = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickExportDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _exportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _exportDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
      _dateController.text = dateFormatter.format(_exportDate);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final productId = _selectedProduct?.productId;
    final quantity = int.tryParse(_quantityController.text.trim());
    if (productId == null || quantity == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final exportResult = await _batchService.exportStock(
        productId: productId,
        quantity: quantity,
      );
      await _reloadAfterExport();

      if (!mounted) return;

      _quantityController.clear();
      setState(() {
        _lastExport = exportResult;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo phiếu xuất thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = apiErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

    if (_errorMessage != null && _products.isEmpty && _batches.isEmpty) {
      return _ExportErrorState(message: _errorMessage!, onReload: _loadData);
    }

    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Tạo giao dịch xuất hàng'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _FieldBox(
                        child: DropdownButtonFormField<ProductResponse>(
                          initialValue: _selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Sản phẩm',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          items: _products
                              .map(
                                (product) => DropdownMenuItem(
                                  value: product,
                                  child: Text(
                                    '${product.productCode} - ${product.productName}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isSubmitting ? null : _onProductChanged,
                          validator: (value) =>
                              value == null ? 'Vui lòng chọn sản phẩm' : null,
                        ),
                      ),
                      _FieldBox(
                        child: TextFormField(
                          controller: _quantityController,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng xuất',
                            prefixIcon: Icon(Icons.outbox_outlined),
                            helperText:
                                'Hệ thống tự động chọn lô theo FIFO/FEFO',
                          ),
                          validator: _quantityValidator,
                        ),
                      ),
                      _FieldBox(
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Ngày xuất',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          onTap: _isSubmitting ? null : _pickExportDate,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: _errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.outbox_outlined),
                    label: Text(
                      _isSubmitting ? 'Đang tạo...' : 'Tạo phiếu xuất',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_lastExport != null) ...[
                    const SizedBox(height: 18),
                    _ExportDetails(exportResult: _lastExport!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Lịch sử xuất hàng'),
                const SizedBox(height: 12),
                DarkTable(
                  columns: const [
                    DataColumn(label: Text('Mã GD')),
                    DataColumn(label: Text('Lô hàng')),
                    DataColumn(label: Text('Số lượng')),
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Ghi chú')),
                  ],
                  rows: (_transactions.where((item) => item.type == 'EXPORT').toList()
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                      .take(5)
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text('GD${item.transactionId}')),
                            DataCell(Text('LH${item.batch?.batchId ?? ''}')),
                            DataCell(Text(item.quantity.toString())),
                            DataCell(
                              Text(dateFormatter.format(item.createdAt)),
                            ),
                            const DataCell(Text('Xuất kho theo lô')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _quantityValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Số lượng xuất không được rỗng';
    }

    final quantity = int.tryParse(text);
    if (quantity == null || quantity <= 0) {
      return 'Số lượng xuất phải lớn hơn 0';
    }

    final product = _selectedProduct;
    if (product != null && quantity > _availableStock) {
      return 'Số lượng xuất không được vượt quá tồn kho hiện có ($_availableStock)';
    }

    return null;
  }
}

class _ExportDetails extends StatelessWidget {
  final InventoryExportResponse exportResult;

  const _ExportDetails({required this.exportResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              SectionTitle('Chi tiết xuất kho'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Đã xuất ${exportResult.exportedQuantity}/${exportResult.requestedQuantity}. '
            'Lô được hệ thống tự động phân bổ theo FIFO/FEFO.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          DarkTable(
            columns: const [
              DataColumn(label: Text('Mã lô')),
              DataColumn(label: Text('Số lượng xuất')),
              DataColumn(label: Text('Còn lại')),
            ],
            rows: exportResult.batches
                .map(
                  (batch) => DataRow(
                    cells: [
                      DataCell(Text('LH${batch.batchId}')),
                      DataCell(Text(batch.exportedQuantity.toString())),
                      DataCell(Text(batch.remainingQuantity.toString())),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ExportErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const _ExportErrorState({required this.message, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Không thể tải dữ liệu xuất hàng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

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

class _FieldBox extends StatelessWidget {
  final Widget child;

  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 300, child: child);
  }
}
