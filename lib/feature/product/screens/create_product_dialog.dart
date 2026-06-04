import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/create_supplier_dialog.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/supplier/service/supplier_service.dart';

class CreateProductDialog extends StatefulWidget {
  const CreateProductDialog({super.key});

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minStockController = TextEditingController(text: '0');
  final _priceController = TextEditingController();
  final ProductService _productService = ProductService();
  final SupplierService _supplierService = SupplierService();

  late Future<List<SupplierResponse>> _suppliersFuture;
  List<SupplierResponse> _suppliers = [];
  SupplierResponse? _selectedSupplier;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _suppliersFuture = _loadSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<List<SupplierResponse>> _loadSuppliers() async {
    final suppliers = await _supplierService.getAllSuppliers();
    _suppliers = suppliers;
    if (_selectedSupplier == null && suppliers.isNotEmpty) {
      _selectedSupplier = suppliers.first;
    }
    return suppliers;
  }

  Future<void> _openCreateSupplierDialog() async {
    final supplier = await showDialog<SupplierResponse>(
      context: context,
      builder: (context) => const CreateSupplierDialog(),
    );

    if (supplier == null || !mounted) return;

    setState(() {
      _suppliers = [..._suppliers, supplier];
      _selectedSupplier = supplier;
      _suppliersFuture = Future.value(_suppliers);
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final supplier = _selectedSupplier;
    if (supplier == null || supplier.supplierId == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn nhà cung cấp';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final product = await _productService.createProduct(
        ProductCreateRequest(
          supplierId: supplier.supplierId,
          productName: _nameController.text.trim(),
          minStockLevel: int.parse(_minStockController.text.trim()),
          price: double.parse(_priceController.text.trim()),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(product);
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: FutureBuilder<List<SupplierResponse>>(
              future: _suppliersFuture,
              builder: (context, snapshot) {
                final isLoadingSuppliers =
                    snapshot.connectionState == ConnectionState.waiting;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tạo sản phẩm',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 560;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              _FieldBox(
                                isWide: isWide,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Product Name',
                                    prefixIcon: Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  validator: _requiredValidator,
                                ),
                              ),
                              SizedBox(
                                width: isWide
                                    ? (constraints.maxWidth - 14)
                                    : constraints.maxWidth,
                                child: isLoadingSuppliers
                                    ? const _LoadingSuppliers()
                                    : _SupplierPicker(
                                        suppliers: _suppliers,
                                        selectedSupplier: _selectedSupplier,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSupplier = value;
                                          });
                                        },
                                        onCreateSupplier:
                                            _openCreateSupplierDialog,
                                      ),
                              ),
                              _FieldBox(
                                isWide: isWide,
                                child: TextFormField(
                                  controller: _minStockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Min Stock Level',
                                    prefixIcon: Icon(Icons.low_priority),
                                  ),
                                  validator: _minStockValidator,
                                ),
                              ),
                              _FieldBox(
                                isWide: isWide,
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                  ),
                                  validator: _priceValidator,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _DialogError(message: _errorMessage!),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting || isLoadingSuppliers
                                ? null
                                : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isSubmitting ? 'Đang tạo...' : 'Tạo sản phẩm',
                            ),
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Trường này không được rỗng'
        : null;
  }

  String? _minStockValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tồn tối thiểu không được rỗng';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Tồn tối thiểu phải lớn hơn hoặc bằng 0';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Giá không được rỗng';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Giá phải lớn hơn 0';
    }
    return null;
  }
}

class _FieldBox extends StatelessWidget {
  final bool isWide;
  final Widget child;

  const _FieldBox({required this.isWide, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: isWide ? 283 : double.infinity, child: child);
  }
}

class _LoadingSuppliers extends StatelessWidget {
  const _LoadingSuppliers();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 58,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Đang tải nhà cung cấp...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierPicker extends StatelessWidget {
  final List<SupplierResponse> suppliers;
  final SupplierResponse? selectedSupplier;
  final ValueChanged<SupplierResponse?> onChanged;
  final VoidCallback onCreateSupplier;

  const _SupplierPicker({
    required this.suppliers,
    required this.selectedSupplier,
    required this.onChanged,
    required this.onCreateSupplier,
  });

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Chưa có nhà cung cấp. Hãy tạo nhà cung cấp trước.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onCreateSupplier,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Tạo nhà cung cấp'),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<SupplierResponse>(
            initialValue: selectedSupplier,
            decoration: const InputDecoration(
              labelText: 'Supplier',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            items: suppliers
                .map(
                  (supplier) => DropdownMenuItem(
                    value: supplier,
                    child: Text(supplier.supplierName),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null ? 'Vui lòng chọn nhà cung cấp' : null,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onCreateSupplier,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Tạo nhà cung cấp'),
          ),
        ),
      ],
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
