import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/data/model/unit_response.dart';
import 'package:smartlogisticssystem/feature/category/service/category_service.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/supplier/service/supplier_service.dart';
import 'package:smartlogisticssystem/feature/unit/unit_service.dart';

class EditProductPage extends StatefulWidget {
  final int productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _supplierService = SupplierService();
  final _unitService = UnitService();

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();

  ProductResponse? _product;
  List<ProductCategoryResponse> _categories = const [];
  List<SupplierResponse> _suppliers = const [];
  List<UnitResponse> _units = const [];

  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedBaseUnitId;
  File? _replacementImage;
  String? _replacementImageName;
  bool _removeImage = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productFuture = _productService.getProductById(widget.productId);
      final categoriesFuture = _categoryService.getAllCategories();
      final suppliersFuture = _supplierService.getAllSuppliers();
      final unitsFuture = _unitService.getAll();

      final product = await productFuture;
      final categories = await categoriesFuture;
      final suppliers = await suppliersFuture;
      final units = await unitsFuture;

      if (!mounted) return;
      _populate(product);
      setState(() {
        _product = product;
        _categories = categories;
        _suppliers = suppliers;
        _units = units;
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

  void _populate(ProductResponse product) {
    _nameCtrl.text = product.productName;
    _skuCtrl.text = product.sku;
    _priceCtrl.text = _numberText(product.price);
    _weightCtrl.text = _numberText(product.weight);
    _lengthCtrl.text = _numberText(product.length);
    _widthCtrl.text = _numberText(product.width);
    _heightCtrl.text = _numberText(product.height);
    _minStockCtrl.text = product.minStockLevel?.toString() ?? '';
    _selectedCategoryId = product.categoryId;
    _selectedSupplierId = product.supplier?.supplierId;
    _selectedBaseUnitId = product.baseUnitId;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );
    final picked = result?.files.single;
    final path = picked?.path;
    if (picked == null || path == null) return;

    final file = File(path);
    final size = await file.length();
    if (size > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ảnh không được vượt quá 5 MB'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _replacementImage = file;
      _replacementImageName = picked.name;
      _removeImage = false;
    });
  }

  void _removeCurrentImage() {
    setState(() {
      _replacementImage = null;
      _replacementImageName = null;
      _removeImage = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final product = _product;
    if (product == null ||
        _selectedCategoryId == null ||
        _selectedSupplierId == null ||
        _selectedBaseUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục, nhà cung cấp và đơn vị tính'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = ProductUpdateRequest(
        productCode: product.productCode,
        productName: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        weight: double.parse(_weightCtrl.text.trim()),
        length: _parseOptionalDouble(_lengthCtrl.text),
        width: _parseOptionalDouble(_widthCtrl.text),
        height: _parseOptionalDouble(_heightCtrl.text),
        baseUnitId: _selectedBaseUnitId,
        minStockLevel: int.tryParse(_minStockCtrl.text.trim()),
        supplierId: _selectedSupplierId,
        categoryId: _selectedCategoryId,
      );

      await _productService.updateProduct(
        widget.productId,
        request,
        imageFile: _replacementImage,
        removeImage: _removeImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật sản phẩm thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/products/${widget.productId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              ? _ErrorState(message: errorMessage, onRetry: _loadData)
              : product == null
              ? const Center(child: Text('Không tìm thấy sản phẩm'))
              : _buildForm(product),
        ),
      ),
    );
  }

  Widget _buildForm(ProductResponse product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          isSubmitting: _isSubmitting,
          onCancel: () => context.go('/products/${widget.productId}'),
          onSubmit: _submit,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 980;
                  final form = Column(
                    children: [
                      _SectionCard(
                        title: 'Thông tin sản phẩm',
                        child: Column(
                          children: [
                            _FormGrid(
                              children: [
                                _TextInput(
                                  label: 'Tên sản phẩm',
                                  controller: _nameCtrl,
                                  requiredMessage: 'Tên sản phẩm là bắt buộc',
                                ),
                                _TextInput(label: 'SKU', controller: _skuCtrl),
                                _DropdownInput<int>(
                                  label: 'Danh mục',
                                  value: _safeCategoryValue,
                                  items: _categories
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.categoryId,
                                          child: Text(item.categoryName),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                                ),
                                _DropdownInput<int>(
                                  label: 'Nhà cung cấp',
                                  value: _safeSupplierValue,
                                  items: _suppliers
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.supplierId,
                                          child: Text(item.supplierName),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedSupplierId = value),
                                ),
                                _DropdownInput<int>(
                                  label: 'Đơn vị tính cơ bản',
                                  value: _safeUnitValue,
                                  items: _units
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.id,
                                          child: Text('${item.code} - ${item.name}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() => _selectedBaseUnitId = value),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Giá, tồn kho và kích thước',
                        child: _FormGrid(
                          children: [
                            _TextInput(
                              label: 'Giá bán',
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              requiredMessage: 'Giá bán là bắt buộc',
                              numeric: true,
                            ),
                            _TextInput(
                              label: 'Trọng lượng',
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              requiredMessage: 'Trọng lượng là bắt buộc',
                              numeric: true,
                            ),
                            _TextInput(
                              label: 'Tồn kho tối thiểu',
                              controller: _minStockCtrl,
                              keyboardType: TextInputType.number,
                              integer: true,
                            ),
                            _TextInput(
                              label: 'Chiều dài',
                              controller: _lengthCtrl,
                              keyboardType: TextInputType.number,
                              numeric: true,
                              optional: true,
                            ),
                            _TextInput(
                              label: 'Chiều rộng',
                              controller: _widthCtrl,
                              keyboardType: TextInputType.number,
                              numeric: true,
                              optional: true,
                            ),
                            _TextInput(
                              label: 'Chiều cao',
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              numeric: true,
                              optional: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final image = _ImageEditor(
                    product: product,
                    replacementImage: _replacementImage,
                    replacementImageName: _replacementImageName,
                    removeImage: _removeImage,
                    onPickImage: _pickImage,
                    onRemoveImage: _removeCurrentImage,
                    onUndoRemove: () => setState(() => _removeImage = false),
                  );

                  if (!isWide) {
                    return Column(
                      children: [
                        form,
                        const SizedBox(height: 16),
                        image,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: image),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  int? get _safeCategoryValue =>
      _categories.any((item) => item.categoryId == _selectedCategoryId) ? _selectedCategoryId : null;

  int? get _safeSupplierValue =>
      _suppliers.any((item) => item.supplierId == _selectedSupplierId) ? _selectedSupplierId : null;

  int? get _safeUnitValue =>
      _units.any((item) => item.id == _selectedBaseUnitId) ? _selectedBaseUnitId : null;
}

class _Header extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _Header({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
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
              width: compact ? constraints.maxWidth : constraints.maxWidth - 340,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard > Quản lý sản phẩm > Chi tiết sản phẩm > Chỉnh sửa',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chỉnh sửa sản phẩm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu thay đổi'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ImageEditor extends StatelessWidget {
  final ProductResponse product;
  final File? replacementImage;
  final String? replacementImageName;
  final bool removeImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onUndoRemove;

  const _ImageEditor({
    required this.product,
    required this.replacementImage,
    required this.replacementImageName,
    required this.removeImage,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onUndoRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageName = replacementImageName;

    return _SectionCard(
      title: 'Hình ảnh sản phẩm',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _imagePreview(),
          const SizedBox(height: 12),
          if (imageName != null)
            Text(
              imageName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          if (removeImage)
            const Text(
              'Ảnh hiện tại sẽ được xóa khi lưu thay đổi.',
              style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Chọn ảnh'),
              ),
              if (_hasCurrentImage || replacementImage != null)
                OutlinedButton.icon(
                  onPressed: removeImage ? onUndoRemove : onRemoveImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: removeImage ? AppColors.primary : AppColors.danger,
                    side: BorderSide(color: removeImage ? AppColors.primary : AppColors.danger),
                  ),
                  icon: Icon(removeImage ? Icons.undo : Icons.delete_outline, size: 18),
                  label: Text(removeImage ? 'Hoàn tác' : 'Xóa ảnh'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasCurrentImage => product.imageUrl?.trim().isNotEmpty == true;

  Widget _imagePreview() {
    final imageFile = replacementImage;
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(imageFile, height: 240, fit: BoxFit.cover),
      );
    }

    final imageUrl = product.imageUrl?.trim() ?? '';
    if (!removeImage && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textSecondary),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _FormGrid extends StatelessWidget {
  final List<Widget> children;

  const _FormGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 680
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? requiredMessage;
  final bool numeric;
  final bool integer;
  final bool optional;

  const _TextInput({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.requiredMessage,
    this.numeric = false,
    this.integer = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (!optional && requiredMessage != null && text.isEmpty) {
          return requiredMessage;
        }
        if (text.isEmpty) return null;
        if (integer && int.tryParse(text) == null) {
          return '$label không hợp lệ';
        }
        if (numeric && double.tryParse(text) == null) {
          return '$label không hợp lệ';
        }
        return null;
      },
    );
  }
}

class _DropdownInput<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownInput({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? '$label là bắt buộc' : null,
    );
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

String _numberText(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

double? _parseOptionalDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}
