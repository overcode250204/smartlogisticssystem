import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
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
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số lượng';
    final qty = int.tryParse(value.trim());
    if (qty == null || qty <= 0) return 'Số lượng phải lớn hơn 0';
    return null;
  }

  String? _expirationValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng chọn ngày hết hạn';
    }
    if (_expirationDate != null && _expirationDate!.isBefore(_importDate)) {
      return 'Ngày hết hạn không được trước ngày tạo';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final quantity = int.parse(_quantityController.text.trim());

      final batch = InventoryBatchCreateRequest(
        productId: _selectedProduct!.productId,
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BarcodeBatchForm(
                formKey: _formKey,
                products: _products,
                selectedProduct: _selectedProduct,
                quantityController: _quantityController,
                importDateController: _importDateController,
                expirationDateController: _expirationDateController,
                supplierController: _supplierController,
                noteController: _noteController,
                received: _received,
                isSubmitting: _isSubmitting,
                errorMessage: _errorMessage,
                onProductChanged: _onProductChanged,
                onImportDateTap: _pickImportDate,
                onExpirationDateTap: _pickExpirationDate,
                onReceivedChanged: (value) {
                  setState(() {
                    _received = value;
                  });
                },
                onSubmit: _submit,
                quantityValidator: _quantityValidator,
                expirationValidator: _expirationValidator,
              ),
              const SizedBox(height: 24),
              BarcodeHistoryTable(
                batches: _batches,
                products: _products,
                errorMessage: _errorMessage,
                confirmingBatchId: _confirmingBatchId,
                onReload: _loadData,
                onConfirmReceived: _confirmReceived,
              ),
            ],
          ),
        ),
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

class BarcodeBatchForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<ProductResponse> products;
  final ProductResponse? selectedProduct;
  final TextEditingController quantityController;
  final TextEditingController importDateController;
  final TextEditingController expirationDateController;
  final TextEditingController supplierController;
  final TextEditingController noteController;
  final bool received;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<ProductResponse?> onProductChanged;
  final VoidCallback onImportDateTap;
  final VoidCallback onExpirationDateTap;
  final ValueChanged<bool> onReceivedChanged;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> quantityValidator;
  final FormFieldValidator<String> expirationValidator;

  const BarcodeBatchForm({
    super.key,
    required this.formKey,
    required this.products,
    required this.selectedProduct,
    required this.quantityController,
    required this.importDateController,
    required this.expirationDateController,
    required this.supplierController,
    required this.noteController,
    required this.received,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onProductChanged,
    required this.onImportDateTap,
    required this.onExpirationDateTap,
    required this.onReceivedChanged,
    required this.onSubmit,
    required this.quantityValidator,
    required this.expirationValidator,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 760;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LargeSectionTitle('Tạo mã vạch lô hàng'),
                const SizedBox(height: 24),
                _ResponsiveFieldRow(
                  isNarrow: isNarrow,
                  children: [
                    ProductSelectorField(
                      products: products,
                      selectedProduct: selectedProduct,
                      enabled: !isSubmitting,
                      onChanged: onProductChanged,
                    ),
                    SupplierSelectorField(controller: supplierController),
                  ],
                ),
                const SizedBox(height: 16),
                _ResponsiveFieldRow(
                  isNarrow: isNarrow,
                  children: [
                    TextFormField(
                      controller: quantityController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      style: _fieldTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        prefixIcon: Icon(Icons.add_box_outlined),
                      ),
                      validator: quantityValidator,
                    ),
                    TextFormField(
                      controller: importDateController,
                      readOnly: true,
                      enabled: !isSubmitting,
                      style: _fieldTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Ngày tạo',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      onTap: isSubmitting ? null : onImportDateTap,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ResponsiveFieldRow(
                  isNarrow: isNarrow,
                  children: [
                    TextFormField(
                      controller: expirationDateController,
                      readOnly: true,
                      enabled: !isSubmitting,
                      style: _fieldTextStyle,
                      decoration: const InputDecoration(
                        labelText: 'Ngày hết hạn',
                        prefixIcon: Icon(Icons.event_busy_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      onTap: isSubmitting ? null : onExpirationDateTap,
                      validator: expirationValidator,
                    ),
                    if (!isNarrow) const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  enabled: !isSubmitting,
                  minLines: 1,
                  maxLines: 3,
                  style: _fieldTextStyle,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ReceivedCheckbox(
                  value: received,
                  enabled: !isSubmitting,
                  onChanged: onReceivedChanged,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _InlineError(message: errorMessage!),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: isNarrow
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: SizedBox(
                    width: isNarrow ? double.infinity : 220,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : onSubmit,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(isSubmitting ? 'Đang tạo...' : 'Tạo mã vạch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProductSelectorField extends StatelessWidget {
  final List<ProductResponse> products;
  final ProductResponse? selectedProduct;
  final bool enabled;
  final ValueChanged<ProductResponse?> onChanged;

  const ProductSelectorField({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProductResponse>(
      initialValue: selectedProduct,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: const InputDecoration(
        labelText: 'Chọn sản phẩm',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      selectedItemBuilder: (context) => products
          .map(
            (product) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fieldTextStyle,
              ),
            ),
          )
          .toList(),
      items: products
          .map(
            (product) => DropdownMenuItem(
              value: product,
              child: _ProductMenuItem(product: product),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? 'Vui lòng chọn sản phẩm' : null,
    );
  }
}

class SupplierSelectorField extends StatelessWidget {
  final TextEditingController controller;

  const SupplierSelectorField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: _fieldTextStyle,
      decoration: const InputDecoration(
        labelText: 'Nhà cung cấp',
        prefixIcon: Icon(Icons.business_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nhà cung cấp chưa có dữ liệu';
        }
        return null;
      },
    );
  }
}

class ReceivedCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const ReceivedCheckbox({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: enabled ? (next) => onChanged(next ?? false) : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
      title: const Text(
        'Lô hàng đã được nhận vào kho',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BarcodeHistoryTable extends StatelessWidget {
  final List<InventoryBatchResponse> batches;
  final List<ProductResponse> products;
  final String? errorMessage;
  final int? confirmingBatchId;
  final VoidCallback onReload;
  final ValueChanged<int> onConfirmReceived;

  const BarcodeHistoryTable({
    super.key,
    required this.batches,
    required this.products,
    required this.errorMessage,
    required this.confirmingBatchId,
    required this.onReload,
    required this.onConfirmReceived,
  });

  @override
  Widget build(BuildContext context) {
    final recentBatches = batches.toList()
      ..sort((a, b) => b.importDate.compareTo(a.importDate));

    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _LargeSectionTitle('Lịch sử tạo mã vạch gần đây'),
              ),
              Tooltip(
                message: 'Tải lại lịch sử',
                child: IconButton(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (errorMessage != null && batches.isEmpty)
            _HistoryMessage(
              icon: Icons.error_outline_rounded,
              title: 'Không thể tải lịch sử',
              message: errorMessage!,
            )
          else if (recentBatches.isEmpty)
            const _HistoryMessage(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có lịch sử tạo mã vạch',
              message: 'Các lô hàng mới tạo sẽ hiển thị tại đây.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.darkest.withValues(alpha: 0.9),
                ),
                columnSpacing: 28,
                horizontalMargin: 16,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Mã lô')),
                  DataColumn(label: Text('Sản phẩm')),
                  DataColumn(label: Text('Số lượng')),
                  DataColumn(label: Text('Nhà cung cấp')),
                  DataColumn(label: Text('Ngày tạo')),
                  DataColumn(label: Text('Trạng thái')),
                ],
                rows: recentBatches.take(8).map(_buildRow).toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildRow(InventoryBatchResponse batch) {
    final product = batch.product;
    final supplierName =
        products
            .where((item) => item.productId == product?.productId)
            .firstOrNull
            ?.supplier
            ?.supplierName ??
        'Chưa có';

    return DataRow(
      cells: [
        DataCell(Text('LH${batch.batchId}')),
        DataCell(_EllipsisCell(product?.productName ?? 'Không có dữ liệu')),
        DataCell(Text(batch.quantity.toString())),
        DataCell(_EllipsisCell(supplierName)),
        DataCell(Text(dateFormatter.format(batch.importDate))),
        DataCell(
          batch.received
              ? const _ReceivedStatusChip(received: true)
              : _ConfirmReceivedButton(
                  isLoading: confirmingBatchId == batch.batchId,
                  isDisabled: confirmingBatchId != null,
                  onPressed: () => onConfirmReceived(batch.batchId),
                ),
        ),
      ],
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  final bool isNarrow;
  final List<Widget> children;

  const _ResponsiveFieldRow({required this.isNarrow, required this.children});

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            SizedBox(width: double.infinity, child: children[index]),
            if (index != children.length - 1) const SizedBox(height: 16),
          ],
        ],
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
  }
}

class _ProductMenuItem extends StatelessWidget {
  final ProductResponse product;

  const _ProductMenuItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final code = product.sku.isNotEmpty ? product.sku : product.productCode;
    return Tooltip(
      message: '${product.productName}${code.isEmpty ? '' : ' - $code'}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _fieldTextStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                code,
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
    );
  }
}

class _ConfirmReceivedButton extends StatelessWidget {
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ConfirmReceivedButton({
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_rounded, size: 16),
      label: const Text('Xác nhận'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ReceivedStatusChip extends StatelessWidget {
  final bool received;

  const _ReceivedStatusChip({required this.received});

  @override
  Widget build(BuildContext context) {
    final color = received ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            received ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            received ? 'Đã nhận' : 'Chưa nhận',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EllipsisCell extends StatelessWidget {
  final String value;

  const _EllipsisCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: SizedBox(
        width: 190,
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.darkest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeSectionTitle extends StatelessWidget {
  final String title;

  const _LargeSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

const _fieldTextStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w500,
);
