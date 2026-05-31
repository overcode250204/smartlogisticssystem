import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_status.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final ProductService _productService = ProductService();
  final InventoryBatchService _batchService = InventoryBatchService();

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _importDateController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();

  List<ProductResponse> _products = [];
  List<InventoryBatchResponse> _batches = [];
  ProductResponse? _selectedProduct;
  int? _confirmingBatchId;

  DateTime _importDate = DateTime.now();
  DateTime? _expirationDate;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _received = false;

  @override
  void initState() {
    super.initState();
    _importDateController.text = dateFormatter.format(_importDate);
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _importDateController.dispose();
    _expirationDateController.dispose();
    _supplierController.dispose();
    _noteController.dispose();
    super.dispose();
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
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<ProductResponse>;
        _batches = results[1] as List<InventoryBatchResponse>;
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

  Future<void> _pickImportDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _importDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _importDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        _importDateController.text = dateFormatter.format(_importDate);
        if (_expirationDate != null && _expirationDate!.isBefore(_importDate)) {
          _expirationDate = null;
          _expirationDateController.clear();
        }
      });
    }
  }

  Future<void> _pickExpirationDate() async {
    final initial =
        _expirationDate ?? _importDate.add(const Duration(days: 30));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_importDate) ? _importDate : initial,
      firstDate: _importDate,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _expirationDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
          59,
        );
        _expirationDateController.text = dateFormatter.format(_expirationDate!);
      });
    }
  }

  void _onProductChanged(ProductResponse? product) {
    setState(() {
      _selectedProduct = product;
      _supplierController.text = product?.supplier?.supplierName ?? '';
    });
  }

  String? _quantityValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
    final qty = int.tryParse(value.trim());
    if (qty == null || qty <= 0) return 'Số lượng > 0';
    return null;
  }

  String? _expirationValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
    if (_expirationDate != null && _expirationDate!.isBefore(_importDate)) {
      return 'Phải sau ngày nhập';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final quantity = int.parse(_quantityController.text.trim());

      final batch = InventoryBatchCreateRequest(
        productId: _selectedProduct!.productId!,
        quantity: quantity,
        remainingQuantity: quantity,
        importDate: _importDate,
        expirationDate: _expirationDate!,
        received: _received,
      );

      await _batchService.createBatch(batch);
      final newBatches = await _batchService.getAllBatches();

      if (!mounted) return;

      setState(() {
        _batches = newBatches;
        _selectedProduct = null;
      });
      _quantityController.clear();
      _supplierController.clear();
      _noteController.clear();
      _expirationDate = null;
      _expirationDateController.clear();
      _received = false;
      _formKey.currentState?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo mã vạch lô hàng thành công'),
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

  Future<void> _confirmReceived(int batchId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Xác nhận nhận hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Bạn chắc chắn đã nhận lô hàng này?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _confirmingBatchId = batchId;
    });

    try {
      await _batchService.confirmReceived(batchId);
      final newBatches = await _batchService.getAllBatches();

      if (!mounted) return;

      setState(() {
        _batches = newBatches;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận nhận hàng thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${apiErrorMessage(error)}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _confirmingBatchId = null;
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
      return _ImportErrorState(message: _errorMessage!, onReload: _loadData);
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
                  const SectionTitle('Tạo mã vạch lô hàng'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _FieldBox(
                        child: DropdownButtonFormField<ProductResponse>(
                          initialValue: _selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Chọn sản phẩm',
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
                          controller: _supplierController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Nhà cung cấp',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                      ),
                      _FieldBox(
                        child: TextFormField(
                          controller: _quantityController,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng',
                            prefixIcon: Icon(Icons.add_box_outlined),
                          ),
                          validator: _quantityValidator,
                        ),
                      ),
                      _FieldBox(
                        child: TextFormField(
                          controller: _importDateController,
                          readOnly: true,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Ngày tạo',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          onTap: _isSubmitting ? null : _pickImportDate,
                        ),
                      ),
                      _FieldBox(
                        child: TextFormField(
                          controller: _expirationDateController,
                          readOnly: true,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Ngày hết hạn',
                            prefixIcon: Icon(Icons.event_busy_outlined),
                          ),
                          onTap: _isSubmitting ? null : _pickExpirationDate,
                          validator: _expirationValidator,
                        ),
                      ),

                      _FieldBox(
                        width: 616,
                        child: TextFormField(
                          controller: _noteController,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ),
                      _FieldBox(
                        child: InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _received = !_received;
                                  });
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 56, // Match standard input height
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _received,
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _received = value ?? false;
                                          });
                                        },
                                ),
                                const SizedBox(width: 8),
                                const Text('Đã nhận', style: TextStyle(color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
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
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(_isSubmitting ? 'Đang tạo...' : 'Tạo mã vạch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Lịch sử tạo mã vạch gần đây'),
                const SizedBox(height: 12),
                DarkTable(
                  columns: const [
                    DataColumn(label: Text('Mã lô')),
                    DataColumn(label: Text('Sản phẩm')),
                    DataColumn(label: Text('Số lượng')),
                    DataColumn(label: Text('Ngày tạo')),
                    DataColumn(label: Text('Đã nhận')),
                  ],
                  rows:
                      (_batches.toList()..sort(
                            (a, b) => b.importDate.compareTo(a.importDate),
                          ))
                          .take(5)
                          .map(
                            (batch) => DataRow(
                              cells: [
                                DataCell(Text('LH${batch.batchId ?? ''}')),
                                DataCell(
                                  Text(
                                    (batch.product?.productName ?? "") ?? '',
                                  ),
                                ),
                                DataCell(Text(batch.quantity.toString())),
                                DataCell(
                                  Text(dateFormatter.format(batch.importDate)),
                                ),
                                DataCell(
                                  batch.received
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.textSecondary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.textSecondary.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: AppColors.textSecondary,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Đã nhận',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: _confirmingBatchId != null
                                              ? null
                                              : () => _confirmReceived(batch.batchId),
                                          icon: _confirmingBatchId == batch.batchId
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check, size: 14),
                                          label: const Text('Xác nhận'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                ),
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
}

class _ImportErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const _ImportErrorState({required this.message, required this.onReload});

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
              'Không thể tải dữ liệu',
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
  final double width;
  final Widget child;

  const _FieldBox({required this.child, this.width = 300});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}
