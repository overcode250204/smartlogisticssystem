import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/unit_response.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/unit/unit_service.dart';

// ─── Mock data ───────────────────────────────────────────────────────────────

const _kCategories = [
  _DropdownOption(id: 1, label: 'Office Furniture'),
  _DropdownOption(id: 2, label: 'Electronics'),
  _DropdownOption(id: 3, label: 'Packaging Materials'),
  _DropdownOption(id: 4, label: 'Food & Beverage'),
];

const _kSuppliers = [
  _DropdownOption(id: 1, label: 'Office Supplies Co.'),
  _DropdownOption(id: 2, label: 'Global Logistics Supplier'),
  _DropdownOption(id: 3, label: 'Smart Warehouse Partner'),
];

const _kCurrencies = ['USD', 'VND', 'EUR'];

// ─── Helpers ─────────────────────────────────────────────────────────────────

List<_DropdownOption> _toDistinctDropdownOptions(List<UnitResponse> units) {
  final seenIds = <int>{};
  return units
      .where((unit) => seenIds.add(unit.id))
      .map(
        (unit) => _DropdownOption(
          id: unit.id,
          label: '${unit.name} (${unit.code})',
          code: unit.code,
        ),
      )
      .toList();
}

_DropdownOption? _safeSelectedOption(
  _DropdownOption? selected,
  List<_DropdownOption> options,
) {
  if (selected == null) return null;
  final matches = options.where((item) => item.id == selected.id).toList();
  if (matches.length != 1) return null;
  return matches.single;
}

UnitResponse? _safeSelectedUnit(
  UnitResponse? selected,
  List<UnitResponse> options,
) {
  if (selected == null) return null;
  final matches = options.where((item) => item.id == selected.id).toList();
  if (matches.length != 1) return null;
  return matches.single;
}

// ─── Model helpers ───────────────────────────────────────────────────────────

class _DropdownOption {
  final int id;
  final String label;
  final String code;

  const _DropdownOption({
    required this.id,
    required this.label,
    this.code = '',
  });

  @override
  bool operator ==(Object other) {
    return other is _DropdownOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _ProductUnit {
  final int id;
  _DropdownOption unit;
  double conversionFactor;

  _ProductUnit({
    required this.id,
    required this.unit,
    this.conversionFactor = 1.0,
  });
}

// ─── Page ────────────────────────────────────────────────────────────────────

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _unitService = UnitService();

  List<UnitResponse> _allUnits = [];
  List<UnitResponse> _weightUnits = [];
  List<UnitResponse> _dimensionUnits = [];
  List<UnitResponse> _quantityUnits = [];
  List<UnitResponse> _volumeUnits = [];
  bool _isLoadingUnits = true;
  String? _unitLoadError;

  // Basic Info
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  File? _selectedImageFile;
  String? _selectedImageName;
  _DropdownOption? _selectedCategory;
  _DropdownOption? _selectedSupplier;

  // Pricing & Stock
  final _priceCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  final _initialQtyCtrl = TextEditingController();
  String _currency = 'USD';
  _DropdownOption? _selectedBaseUnit;

  // Dimensions
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  UnitResponse? _selectedWeightUnit;
  UnitResponse? _selectedDimensionUnit;

  // Status
  bool _isActive = true;

  // Units table
  int _nextUnitId = 2;
  final List<_ProductUnit> _units = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    // Rebuild live preview on any text change
    for (final c in [
      _nameCtrl,
      _codeCtrl,
      _skuCtrl,
      _priceCtrl,
      _lengthCtrl,
      _widthCtrl,
      _heightCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoadingUnits = true;
      _unitLoadError = null;
    });

    try {
      final apiUnits = await _unitService.getAll();

      final uniqueById = <int, UnitResponse>{
        for (final unit in apiUnits) unit.id: unit,
      }.values.toList();

      final weightUnits = uniqueById
          .where((unit) => unit.type == UnitType.WEIGHT)
          .toList();

      final dimensionUnits = uniqueById
          .where((unit) => unit.type == UnitType.DIMENSION)
          .toList();

      final quantityUnits = uniqueById
          .where((unit) => unit.type == UnitType.QUANTITY)
          .toList();

      final volumeUnits = uniqueById
          .where((unit) => unit.type == UnitType.VOLUME)
          .toList();

      for (final unit in uniqueById) {
        debugPrint(
          'UNIT: id=${unit.id}, code=${unit.code}, '
          'name=${unit.name}, type=${unit.type.name}',
        );
      }

      debugPrint('Weight: ${weightUnits.map((e) => e.code).join(", ")}');
      debugPrint('Dimension: ${dimensionUnits.map((e) => e.code).join(", ")}');
      debugPrint('Quantity: ${quantityUnits.map((e) => e.code).join(", ")}');
      debugPrint('Volume: ${volumeUnits.map((e) => e.code).join(", ")}');

      if (!mounted) return;

      setState(() {
        _allUnits = uniqueById;
        _weightUnits = weightUnits;
        _dimensionUnits = dimensionUnits;
        _quantityUnits = quantityUnits;
        _volumeUnits = volumeUnits;

        _selectedWeightUnit = weightUnits.isNotEmpty ? weightUnits.first : null;

        _selectedDimensionUnit = dimensionUnits.isNotEmpty
            ? dimensionUnits.first
            : null;

        final quantityOptions = _toDistinctDropdownOptions(quantityUnits);

        _selectedBaseUnit = quantityOptions.isEmpty
            ? null
            : quantityOptions.firstWhere(
                (unit) => unit.code == 'PCS',
                orElse: () => quantityOptions.first,
              );
        final allUnitOptions = _toDistinctDropdownOptions(uniqueById);

        _units.clear();
        _nextUnitId = 1;

        for (final option in allUnitOptions) {
          _units.add(
            _ProductUnit(
              id: _nextUnitId++,
              unit: option,
              conversionFactor: 1.0,
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Load units error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _unitLoadError = 'Không thể tải danh sách đơn vị.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _codeCtrl,
      _skuCtrl,
      _descCtrl,
      _priceCtrl,
      _minStockCtrl,
      _reorderCtrl,
      _initialQtyCtrl,
      _weightCtrl,
      _lengthCtrl,
      _widthCtrl,
      _heightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved locally'),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickProductImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;

      if (pickedFile.path == null) {
        throw Exception('Không lấy được đường dẫn file ảnh');
      }

      final selectedFile = File(pickedFile.path!);

      const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
      final fileSize = await selectedFile.length();

      if (fileSize > maxSizeBytes) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh không được vượt quá 5 MB'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImageFile = selectedFile;
        _selectedImageName = pickedFile.name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _removeProductImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null ||
        _selectedSupplier == null ||
        _selectedBaseUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn Danh mục, Nhà cung cấp và Đơn vị cơ bản',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Gửi weightUnitId, dimensionUnitId, product unit conversions khi backend hỗ trợ
      final request = ProductCreateRequest(
        productName: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        weight: double.tryParse(_weightCtrl.text.trim()) ?? 0,
        length: double.tryParse(_lengthCtrl.text.trim()),
        width: double.tryParse(_widthCtrl.text.trim()),
        height: double.tryParse(_heightCtrl.text.trim()),
        baseUnitId: _selectedBaseUnit!.id,
        minStockLevel: int.tryParse(_minStockCtrl.text.trim()),
        supplierId: _selectedSupplier!.id,
        categoryId: _selectedCategory!.id,
      );

      final createdProduct = await _productService.createProduct(
        request,
        imageFile: _selectedImageFile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tạo sản phẩm "${createdProduct.productName}" thành công',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/inventory');
    } on DioException catch (e) {
      if (!mounted) return;

      final responseData = e.response?.data;
      String message = 'Không thể tạo sản phẩm';

      if (responseData is Map) {
        message =
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            responseData['code']?.toString() ??
            message;
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo sản phẩm thất bại: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _addUnit() {
    final options = _toDistinctDropdownOptions(_quantityUnits);
    final selectedIds = _units.map((row) => row.unit.id).toSet();
    final availableOptions = options
        .where((option) => !selectedIds.contains(option.id))
        .toList();

    if (availableOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tất cả đơn vị số lượng đã được thêm.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _units.add(
        _ProductUnit(
          id: _nextUnitId++,
          unit: availableOptions.first,
          conversionFactor: 1.0,
        ),
      );
    });
  }

  void _removeUnit(int id) {
    final unit = _units.firstWhere((item) => item.id == id);

    if (unit.unit.id == _selectedBaseUnit?.id) {
      return;
    }

    setState(() {
      _units.removeWhere((item) => item.id == id);
    });
  }

  void _onBaseUnitChanged(_DropdownOption? newBaseUnit) {
    if (newBaseUnit == null || newBaseUnit.id == _selectedBaseUnit?.id) {
      return;
    }

    setState(() {
      _selectedBaseUnit = newBaseUnit;

      final exists = _units.any((row) => row.unit.id == newBaseUnit.id);

      if (!exists) {
        _units.insert(
          0,
          _ProductUnit(
            id: _nextUnitId++,
            unit: newBaseUnit,
            conversionFactor: 1.0,
          ),
        );
      }

      for (final row in _units) {
        if (row.unit.id == newBaseUnit.id) {
          row.conversionFactor = 1.0;
        }
      }
    });
  }

  void _onUnitChanged(int id, _DropdownOption? newUnit) {
    if (newUnit == null) return;

    final exists = _units.any((u) => u.id != id && u.unit.id == newUnit.id);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn vị này đã được thêm trong bảng quy đổi.'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() {});
      return;
    }

    setState(() {
      final u = _units.firstWhere((u) => u.id == id);
      u.unit = newUnit;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: _isLoadingUnits
          ? const Center(child: CircularProgressIndicator())
          : _unitLoadError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải danh sách đơn vị:\n$_unitLoadError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUnits,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeader(
                      isSubmitting: _isSubmitting,
                      onBack: () => context.go('/inventory'),
                      onDraft: _saveDraft,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 900;
                        if (narrow) {
                          return Column(
                            children: [
                              _leftColumn(),
                              const SizedBox(height: 20),
                              _rightColumn(),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 68, child: _leftColumn()),
                            const SizedBox(width: 20),
                            Expanded(flex: 32, child: _rightColumn()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _leftColumn() {
    final quantityOptions = _toDistinctDropdownOptions(_quantityUnits);
    final allUnitOptions = _toDistinctDropdownOptions(_allUnits);

    return Column(
      children: [
        _BasicInformationSection(
          nameCtrl: _nameCtrl,
          codeCtrl: _codeCtrl,
          skuCtrl: _skuCtrl,
          descCtrl: _descCtrl,
          selectedImageFile: _selectedImageFile,
          selectedImageName: _selectedImageName,
          onPickImage: _pickProductImage,
          onRemoveImage: _removeProductImage,
          selectedCategory: _selectedCategory,
          selectedSupplier: _selectedSupplier,
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
          onSupplierChanged: (v) => setState(() => _selectedSupplier = v),
        ),
        const SizedBox(height: 20),
        _ProductUnitsSection(
          units: _units,
          baseUnit: _selectedBaseUnit,
          quantityOptions: allUnitOptions,
          onAddUnit: _addUnit,
          onRemoveUnit: _removeUnit,
          onUnitChanged: _onUnitChanged,
          onFactorChanged: (id, factor) {
            setState(() {
              final u = _units.firstWhere((u) => u.id == id);
              u.conversionFactor = factor;
            });
          },
        ),
        const SizedBox(height: 20),
        _DimensionsSection(
          weightCtrl: _weightCtrl,
          lengthCtrl: _lengthCtrl,
          widthCtrl: _widthCtrl,
          heightCtrl: _heightCtrl,
          weightUnits: _weightUnits,
          dimensionUnits: _dimensionUnits,
          weightUnit: _selectedWeightUnit,
          dimUnit: _selectedDimensionUnit,
          onWeightUnitChanged: (v) => setState(() => _selectedWeightUnit = v),
          onDimUnitChanged: (v) => setState(() => _selectedDimensionUnit = v),
        ),
        const SizedBox(height: 20),
        _ProductUnitsSection(
          units: _units,
          baseUnit: _selectedBaseUnit,
          quantityOptions: quantityOptions,
          onAddUnit: _addUnit,
          onRemoveUnit: _removeUnit,
          onUnitChanged: _onUnitChanged,
          onFactorChanged: (id, factor) {
            setState(() {
              final u = _units.firstWhere((u) => u.id == id);
              u.conversionFactor = factor;
            });
          },
        ),
      ],
    );
  }

  Widget _rightColumn() {
    return Column(
      children: [
        // Status toggle
        _SectionCard(
          title: 'Product Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Inactive products cannot be selected in new inventory operations.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProductPreviewCard(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          imageFile: _selectedImageFile,
          category: _selectedCategory?.label,
          supplier: _selectedSupplier?.label,
          price: _priceCtrl.text.trim(),
          currency: _currency,
          baseUnit: _selectedBaseUnit,
          isActive: _isActive,
        ),
        const SizedBox(height: 16),
        const _QuickTipsCard(),
      ],
    );
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onDraft;
  final VoidCallback onSubmit;

  const _PageHeader({
    required this.isSubmitting,
    required this.onBack,
    required this.onDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            _Crumb(label: 'Dashboard', onTap: () => context.go('/inventory')),
            const _CrumbSep(),
            _Crumb(label: 'Products', onTap: () => context.go('/inventory')),
            const _CrumbSep(),
            const Text(
              'Create Product',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Product',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add product information, pricing, dimensions, and inventory configuration.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onDraft,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(isSubmitting ? 'Creating...' : 'Create Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Crumb({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.info,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CrumbSep extends StatelessWidget {
  const _CrumbSep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ─── Section Card wrapper ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? titleAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.titleAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?titleAction,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

// ─── Basic Information ────────────────────────────────────────────────────────

class _BasicInformationSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController skuCtrl;
  final TextEditingController descCtrl;

  final File? selectedImageFile;
  final String? selectedImageName;
  final Future<void> Function() onPickImage;
  final VoidCallback onRemoveImage;

  final _DropdownOption? selectedCategory;
  final _DropdownOption? selectedSupplier;
  final ValueChanged<_DropdownOption?> onCategoryChanged;
  final ValueChanged<_DropdownOption?> onSupplierChanged;

  const _BasicInformationSection({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.skuCtrl,
    required this.descCtrl,
    required this.selectedImageFile,
    required this.selectedImageName,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.selectedCategory,
    required this.selectedSupplier,
    required this.onCategoryChanged,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          // Row 1: Name + Code
          _FormRow(
            children: [
              _FormField(
                label: 'Product Name *',
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ergonomic Office Chair',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Product name is required'
                      : null,
                ),
              ),
              _FormField(
                label: 'Product Code',
                child: TextFormField(
                  controller: codeCtrl,
                  enabled: false,
                  decoration: const InputDecoration(
                    hintText: 'Tự động tạo sau khi lưu sản phẩm',
                    prefixIcon: Icon(Icons.auto_awesome_outlined, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: SKU + Category
          _FormRow(
            children: [
              _FormField(
                label: 'SKU',
                child: TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. CH-ERG-001',
                  ),
                ),
              ),
              _FormField(
                label: 'Category *',
                child: DropdownButtonFormField<_DropdownOption>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category',
                  ),
                  items: _kCategories
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: onCategoryChanged,
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: Supplier full width
          _FormField(
            label: 'Supplier *',
            fullWidth: true,
            child: DropdownButtonFormField<_DropdownOption>(
              value: selectedSupplier,
              decoration: const InputDecoration(hintText: 'Select supplier'),
              items: _kSuppliers
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: onSupplierChanged,
              validator: (v) => v == null ? 'Supplier is required' : null,
            ),
          ),
          const SizedBox(height: 16),
          // Row 4: Description
          _FormField(
            label: 'Product Description',
            fullWidth: true,
            child: TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Short description of the product...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Product Image',
            fullWidth: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Chọn ảnh sản phẩm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                  ),
                ),
                const SizedBox(height: 12),
                _ImagePreviewPlaceholder(
                  imageFile: selectedImageFile,
                  imageName: selectedImageName,
                  onRemove: onRemoveImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewPlaceholder extends StatelessWidget {
  final File? imageFile;
  final String? imageName;
  final VoidCallback onRemove;

  const _ImagePreviewPlaceholder({
    required this.imageFile,
    required this.imageName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.darkest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary,
              size: 36,
            ),
            SizedBox(height: 8),
            Text(
              'Chưa chọn ảnh sản phẩm',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Hỗ trợ JPG, JPEG, PNG, WEBP',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.file(
              imageFile!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.danger,
                    size: 40,
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageName ?? 'product-image',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa ảnh',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pricing & Stock ─────────────────────────────────────────────────────────

class _PricingStockSection extends StatelessWidget {
  final TextEditingController priceCtrl;
  final TextEditingController minStockCtrl;
  final TextEditingController reorderCtrl;
  final TextEditingController initialQtyCtrl;
  final String currency;
  final List<_DropdownOption> quantityOptions;
  final _DropdownOption? selectedBaseUnit;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<_DropdownOption?> onBaseUnitChanged;

  const _PricingStockSection({
    required this.priceCtrl,
    required this.minStockCtrl,
    required this.reorderCtrl,
    required this.initialQtyCtrl,
    required this.currency,
    required this.quantityOptions,
    required this.selectedBaseUnit,
    required this.onCurrencyChanged,
    required this.onBaseUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeBaseUnit = _safeSelectedOption(selectedBaseUnit, quantityOptions);

    return _SectionCard(
      title: 'Pricing & Stock Settings',
      child: Column(
        children: [
          // Row 1: Price + Currency
          _FormRow(
            children: [
              _FormField(
                label: 'Unit Price *',
                child: TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0) return 'Enter a valid price ≥ 0';
                    return null;
                  },
                ),
              ),
              _FormField(
                label: 'Currency',
                child: DropdownButtonFormField<String>(
                  value: currency,
                  items: _kCurrencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: onCurrencyChanged,
                  decoration: const InputDecoration(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Base Unit + Min Stock
          _FormRow(
            children: [
              _FormField(
                label: 'Base Unit *',
                child: DropdownButtonFormField<_DropdownOption>(
                  value: safeBaseUnit,
                  decoration: const InputDecoration(
                    hintText: 'Select base unit',
                  ),
                  items: quantityOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: onBaseUnitChanged,
                  validator: (v) => v == null ? 'Base unit is required' : null,
                ),
              ),
              _FormField(
                label: 'Minimum Stock Level *',
                child: TextFormField(
                  controller: minStockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: '0'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Min stock is required';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: Reorder + Initial Qty
          _FormRow(
            children: [
              _FormField(
                label: 'Reorder Point',
                child: TextFormField(
                  controller: reorderCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: '0'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n != null && n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
              ),
              _FormField(
                label: 'Initial Quantity',
                child: TextFormField(
                  controller: initialQtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: '0'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n != null && n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dimensions ───────────────────────────────────────────────────────────────

class _DimensionsSection extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController heightCtrl;

  final List<UnitResponse> weightUnits;
  final List<UnitResponse> dimensionUnits;

  final UnitResponse? weightUnit;
  final UnitResponse? dimUnit;

  final ValueChanged<UnitResponse?> onWeightUnitChanged;
  final ValueChanged<UnitResponse?> onDimUnitChanged;

  const _DimensionsSection({
    required this.weightCtrl,
    required this.lengthCtrl,
    required this.widthCtrl,
    required this.heightCtrl,
    required this.weightUnits,
    required this.dimensionUnits,
    required this.weightUnit,
    required this.dimUnit,
    required this.onWeightUnitChanged,
    required this.onDimUnitChanged,
  });

  String get _dimSummary {
    final l = lengthCtrl.text.trim();
    final w = widthCtrl.text.trim();
    final h = heightCtrl.text.trim();
    final lv = double.tryParse(l);
    final wv = double.tryParse(w);
    final hv = double.tryParse(h);
    final dimCode = dimUnit?.code ?? '';
    if (lv != null && wv != null && hv != null) {
      return '${lv.toStringAsFixed(3)} × ${wv.toStringAsFixed(3)} × ${hv.toStringAsFixed(3)} $dimCode';
    }
    return '-- $dimCode';
  }

  @override
  Widget build(BuildContext context) {
    final safeWeightUnit = _safeSelectedUnit(weightUnit, weightUnits);
    final safeDimUnit = _safeSelectedUnit(dimUnit, dimensionUnits);

    return _SectionCard(
      title: 'Dimensions & Specifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Weight + Weight Unit
          _FormRow(
            children: [
              _FormField(
                label: 'Weight',
                child: TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(hintText: '0.000'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim());
                    if (n != null && n < 0) return 'Must be ≥ 0';
                    return null;
                  },
                ),
              ),
              _FormField(
                label: 'Weight Unit',
                child: DropdownButtonFormField<UnitResponse>(
                  value: safeWeightUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  selectedItemBuilder: (context) {
                    return weightUnits
                        .map(
                          (u) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              u.code,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList();
                  },
                  items: weightUnits
                      .map(
                        (u) => DropdownMenuItem<UnitResponse>(
                          value: u,
                          child: Text(
                            '${u.name} (${u.code})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onWeightUnitChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: L + W + H + Dim Unit
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Length',
                  child: TextFormField(
                    controller: lengthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(hintText: '0.000'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormField(
                  label: 'Width',
                  child: TextFormField(
                    controller: widthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(hintText: '0.000'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormField(
                  label: 'Height',
                  child: TextFormField(
                    controller: heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(hintText: '0.000'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _FormField(
                  label: 'Unit',
                  child: DropdownButtonFormField<UnitResponse>(
                    value: safeDimUnit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    selectedItemBuilder: (context) {
                      return dimensionUnits
                          .map(
                            (u) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                u.code,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList();
                    },
                    items: dimensionUnits
                        .map(
                          (u) => DropdownMenuItem<UnitResponse>(
                            value: u,
                            child: Text(
                              '${u.name} (${u.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onDimUnitChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.straighten_outlined,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dimensions (L × W × H): $_dimSummary',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Units ───────────────────────────────────────────────────────────

class _ProductUnitsSection extends StatelessWidget {
  final List<_ProductUnit> units;
  final _DropdownOption? baseUnit;
  final List<_DropdownOption> quantityOptions;
  final VoidCallback onAddUnit;
  final ValueChanged<int> onRemoveUnit;
  final void Function(int id, _DropdownOption? unit) onUnitChanged;
  final void Function(int id, double factor) onFactorChanged;

  const _ProductUnitsSection({
    required this.units,
    required this.baseUnit,
    required this.quantityOptions,
    required this.onAddUnit,
    required this.onRemoveUnit,
    required this.onUnitChanged,
    required this.onFactorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final baseCode = baseUnit?.code ?? 'BASE';

    return _SectionCard(
      title: 'Product Units & Conversion',
      subtitle: 'Define packaging units and how they convert to the base unit.',
      titleAction: TextButton.icon(
        onPressed: onAddUnit,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Unit'),
        style: TextButton.styleFrom(foregroundColor: AppColors.info),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.darkest),
          border: TableBorder.all(
            color: AppColors.border,
            width: 0.5,
            borderRadius: BorderRadius.circular(8),
          ),
          columnSpacing: 24,
          columns: const [
            DataColumn(
              label: Text('#', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            DataColumn(
              label: Text(
                'Unit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Conversion Factor',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Equivalent to Base Unit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
          rows: units.asMap().entries.map((entry) {
            final idx = entry.key;
            final u = entry.value;
            final isBase = u.unit.id == baseUnit?.id;
            final equiv = '${u.conversionFactor.toStringAsFixed(4)} $baseCode';
            final safeUnit = _safeSelectedOption(u.unit, quantityOptions);

            return DataRow(
              cells: [
                DataCell(Text('${idx + 1}')),
                DataCell(
                  isBase
                      ? Row(
                          children: [
                            Text(u.unit.label),
                            const SizedBox(width: 8),
                            const _Badge(
                              label: 'Base Unit',
                              color: AppColors.info,
                            ),
                          ],
                        )
                      : SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<_DropdownOption>(
                            value: safeUnit,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: quantityOptions
                                .map(
                                  (opt) => DropdownMenuItem(
                                    value: opt,
                                    child: Text(opt.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => onUnitChanged(u.id, v),
                          ),
                        ),
                ),
                DataCell(
                  isBase
                      ? const Text('1.0000')
                      : SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue: u.conversionFactor.toStringAsFixed(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (v) {
                              final f = double.tryParse(v);
                              if (f != null && f > 0) onFactorChanged(u.id, f);
                            },
                          ),
                        ),
                ),
                DataCell(Text(equiv)),
                DataCell(
                  isBase
                      ? const Text(
                          '—',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.info,
                              ),
                              tooltip: 'Edit',
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              tooltip: 'Remove',
                              onPressed: () => onRemoveUnit(u.id),
                            ),
                          ],
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Live Product Preview ─────────────────────────────────────────────────────

class _ProductPreviewCard extends StatelessWidget {
  final String name;
  final String code;
  final File? imageFile;
  final String? category;
  final String? supplier;
  final String price;
  final String currency;
  final _DropdownOption? baseUnit;
  final bool isActive;

  const _ProductPreviewCard({
    required this.name,
    required this.code,
    required this.imageFile,
    required this.category,
    required this.supplier,
    required this.price,
    required this.currency,
    required this.baseUnit,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Product Name' : name;
    final displayCode = code.isEmpty ? 'Auto-generated' : code;
    final displayPrice = price.isEmpty
        ? '—'
        : '$currency ${double.tryParse(price)?.toStringAsFixed(2) ?? price}';

    return _SectionCard(
      title: 'Live Product Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.darkest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageFile != null
                ? Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.border,
                      size: 40,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.border,
                    size: 40,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Badge(
                label: isActive ? 'Active' : 'Inactive',
                color: isActive ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayCode,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          if (category != null)
            _PreviewRow(label: 'Category', value: category!),
          if (supplier != null)
            _PreviewRow(label: 'Supplier', value: supplier!),
          _PreviewRow(label: 'Price', value: displayPrice),
          if (baseUnit != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Text(
                    'Base Unit  ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  _Badge(
                    label: baseUnit!.code.isEmpty
                        ? baseUnit!.label
                        : baseUnit!.code,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Tips ───────────────────────────────────────────────────────────────

class _QuickTipsCard extends StatelessWidget {
  const _QuickTipsCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Quick Tips',
      child: Column(
        children: [
          _TipItem(
            icon: Icons.tag_outlined,
            text: 'Product code should be unique across the system.',
          ),
          SizedBox(height: 12),
          _TipItem(
            icon: Icons.notification_important_outlined,
            text: 'Set a reorder point to avoid running out of stock.',
          ),
          SizedBox(height: 12),
          _TipItem(
            icon: Icons.inventory_2_outlined,
            text:
                'Use units to define boxes, cartons, and pallets for logistics.',
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.info),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared layout helpers ────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final List<Widget> children;

  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand(
                (child) => [Expanded(child: child), const SizedBox(width: 14)],
              )
              .toList()
            ..removeLast(),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool fullWidth;

  const _FormField({
    required this.label,
    required this.child,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: field);
    return field;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
