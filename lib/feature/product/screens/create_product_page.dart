import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';

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

const _kBaseUnits = [
  _DropdownOption(id: 1, label: 'Piece (PCS)', code: 'PCS'),
  _DropdownOption(id: 2, label: 'Box (BOX)', code: 'BOX'),
  _DropdownOption(id: 3, label: 'Carton (CTN)', code: 'CTN'),
  _DropdownOption(id: 4, label: 'Pallet (PLT)', code: 'PLT'),
];

const _kCurrencies = ['USD', 'VND', 'EUR'];
const _kWeightUnits = ['kg', 'g', 'lb'];
const _kDimUnits = ['cm', 'mm', 'm', 'in'];

// ─── Model helpers ───────────────────────────────────────────────────────────

class _DropdownOption {
  final int id;
  final String label;
  final String code;

  const _DropdownOption({required this.id, required this.label, this.code = ''});

  @override
  bool operator ==(Object other) => other is _DropdownOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _ProductUnit {
  final int id;
  _DropdownOption unit;
  double conversionFactor;

  _ProductUnit({required this.id, required this.unit, this.conversionFactor = 1.0});
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

  // Basic Info
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
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
  String _weightUnit = 'kg';
  String _dimUnit = 'cm';

  // Status
  bool _isActive = true;

  // Units table
  int _nextUnitId = 2;
  final List<_ProductUnit> _units = [
    _ProductUnit(
      id: 1,
      unit: _kBaseUnits[0],
      conversionFactor: 1.0,
    ),
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Rebuild live preview on any text change
    for (final c in [
      _nameCtrl, _codeCtrl, _skuCtrl, _imageCtrl,
      _priceCtrl, _lengthCtrl, _widthCtrl, _heightCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _codeCtrl, _skuCtrl, _descCtrl, _imageCtrl,
      _priceCtrl, _minStockCtrl, _reorderCtrl, _initialQtyCtrl,
      _weightCtrl, _lengthCtrl, _widthCtrl, _heightCtrl,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSupplier == null || _selectedBaseUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Category, Supplier, and Base Unit'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build the request object – ready to connect to ProductService
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

      // TODO: uncomment when backend is ready
      // await _productService.createProduct(request);

      // Simulate a short network delay for UX
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/inventory');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addUnit() {
    setState(() {
      _units.add(
        _ProductUnit(
          id: _nextUnitId++,
          unit: _kBaseUnits[1],
          conversionFactor: 1.0,
        ),
      );
    });
  }

  void _removeUnit(int id) {
    if (id == 1) return; // cannot remove base unit row
    setState(() => _units.removeWhere((u) => u.id == id));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: Form(
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
    return Column(
      children: [
        _BasicInformationSection(
          nameCtrl: _nameCtrl,
          codeCtrl: _codeCtrl,
          skuCtrl: _skuCtrl,
          descCtrl: _descCtrl,
          imageCtrl: _imageCtrl,
          selectedCategory: _selectedCategory,
          selectedSupplier: _selectedSupplier,
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
          onSupplierChanged: (v) => setState(() => _selectedSupplier = v),
        ),
        const SizedBox(height: 20),
        _PricingStockSection(
          priceCtrl: _priceCtrl,
          minStockCtrl: _minStockCtrl,
          reorderCtrl: _reorderCtrl,
          initialQtyCtrl: _initialQtyCtrl,
          currency: _currency,
          selectedBaseUnit: _selectedBaseUnit,
          onCurrencyChanged: (v) => setState(() => _currency = v!),
          onBaseUnitChanged: (v) => setState(() => _selectedBaseUnit = v),
        ),
        const SizedBox(height: 20),
        _DimensionsSection(
          weightCtrl: _weightCtrl,
          lengthCtrl: _lengthCtrl,
          widthCtrl: _widthCtrl,
          heightCtrl: _heightCtrl,
          weightUnit: _weightUnit,
          dimUnit: _dimUnit,
          onWeightUnitChanged: (v) => setState(() => _weightUnit = v!),
          onDimUnitChanged: (v) => setState(() => _dimUnit = v!),
        ),
        const SizedBox(height: 20),
        _ProductUnitsSection(
          units: _units,
          baseUnit: _selectedBaseUnit,
          onAddUnit: _addUnit,
          onRemoveUnit: _removeUnit,
          onUnitChanged: (id, unit) {
            setState(() {
              final u = _units.firstWhere((u) => u.id == id);
              u.unit = unit;
            });
          },
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
                    activeColor: AppColors.success,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Inactive products cannot be selected in new inventory operations.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProductPreviewCard(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
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
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(isSubmitting ? 'Creating...' : 'Create Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        style: const TextStyle(color: AppColors.info, fontSize: 13, fontWeight: FontWeight.w500),
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
      child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
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
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                if (titleAction != null) titleAction!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
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
  final TextEditingController imageCtrl;
  final _DropdownOption? selectedCategory;
  final _DropdownOption? selectedSupplier;
  final ValueChanged<_DropdownOption?> onCategoryChanged;
  final ValueChanged<_DropdownOption?> onSupplierChanged;

  const _BasicInformationSection({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.skuCtrl,
    required this.descCtrl,
    required this.imageCtrl,
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
          _FormRow(children: [
            _FormField(
              label: 'Product Name *',
              child: TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Ergonomic Office Chair'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
              ),
            ),
            _FormField(
              label: 'Product Code *',
              child: TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(hintText: 'e.g. PRD-CH-001'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Product code is required' : null,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Row 2: SKU + Category
          _FormRow(children: [
            _FormField(
              label: 'SKU',
              child: TextFormField(
                controller: skuCtrl,
                decoration: const InputDecoration(hintText: 'e.g. CH-ERG-001'),
              ),
            ),
            _FormField(
              label: 'Category *',
              child: DropdownButtonFormField<_DropdownOption>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(hintText: 'Select category'),
                items: _kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: onCategoryChanged,
                validator: (v) => v == null ? 'Category is required' : null,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Row 3: Supplier full width
          _FormField(
            label: 'Supplier *',
            fullWidth: true,
            child: DropdownButtonFormField<_DropdownOption>(
              initialValue: selectedSupplier,
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
              decoration: const InputDecoration(hintText: 'Short description of the product...'),
            ),
          ),
          const SizedBox(height: 16),
          // Row 5: Image URL
          _FormField(
            label: 'Product Image URL',
            fullWidth: true,
            child: TextFormField(
              controller: imageCtrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/images/product.jpg',
                prefixIcon: Icon(Icons.link, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Image preview placeholder
          _ImagePreviewPlaceholder(imageUrl: imageCtrl.text.trim()),
        ],
      ),
    );
  }
}

class _ImagePreviewPlaceholder extends StatelessWidget {
  final String imageUrl;
  const _ImagePreviewPlaceholder({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty;
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.darkest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 36),
        SizedBox(height: 8),
        Text(
          'Image preview will appear here',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        SizedBox(height: 4),
        Text(
          'Enter a valid image URL above',
          style: TextStyle(color: AppColors.border, fontSize: 12),
        ),
      ],
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
  final _DropdownOption? selectedBaseUnit;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<_DropdownOption?> onBaseUnitChanged;

  const _PricingStockSection({
    required this.priceCtrl,
    required this.minStockCtrl,
    required this.reorderCtrl,
    required this.initialQtyCtrl,
    required this.currency,
    required this.selectedBaseUnit,
    required this.onCurrencyChanged,
    required this.onBaseUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pricing & Stock Settings',
      child: Column(
        children: [
          // Row 1: Price + Currency
          _FormRow(children: [
            _FormField(
              label: 'Unit Price *',
              child: TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.attach_money, size: 18)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
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
                items: _kCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: onCurrencyChanged,
                decoration: const InputDecoration(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Row 2: Base Unit + Min Stock
          _FormRow(children: [
            _FormField(
              label: 'Base Unit *',
              child: DropdownButtonFormField<_DropdownOption>(
                initialValue: selectedBaseUnit,
                decoration: const InputDecoration(hintText: 'Select base unit'),
                items: _kBaseUnits
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
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
                  if (v == null || v.trim().isEmpty) return 'Min stock is required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Must be ≥ 0';
                  return null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Row 3: Reorder + Initial Qty
          _FormRow(children: [
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
          ]),
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
  final String weightUnit;
  final String dimUnit;
  final ValueChanged<String?> onWeightUnitChanged;
  final ValueChanged<String?> onDimUnitChanged;

  const _DimensionsSection({
    required this.weightCtrl,
    required this.lengthCtrl,
    required this.widthCtrl,
    required this.heightCtrl,
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
    if (lv != null && wv != null && hv != null) {
      return '${lv.toStringAsFixed(3)} × ${wv.toStringAsFixed(3)} × ${hv.toStringAsFixed(3)} $dimUnit';
    }
    return '-- $dimUnit';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Dimensions & Specifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Weight + Weight Unit
          _FormRow(children: [
            _FormField(
              label: 'Weight',
              child: TextFormField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
              child: DropdownButtonFormField<String>(
                value: weightUnit,
                items: _kWeightUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: onWeightUnitChanged,
                decoration: const InputDecoration(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Row 2: L + W + H + Dim Unit
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Length',
                  child: TextFormField(
                    controller: lengthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(hintText: '0.000'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormField(
                  label: 'Unit',
                  child: DropdownButtonFormField<String>(
                    value: dimUnit,
                    items: _kDimUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: onDimUnitChanged,
                    decoration: const InputDecoration(),
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
                const Icon(Icons.straighten_outlined, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Dimensions (L × W × H): $_dimSummary',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
  final VoidCallback onAddUnit;
  final ValueChanged<int> onRemoveUnit;
  final void Function(int id, _DropdownOption unit) onUnitChanged;
  final void Function(int id, double factor) onFactorChanged;

  const _ProductUnitsSection({
    required this.units,
    required this.baseUnit,
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
          border: TableBorder.all(color: AppColors.border, width: 0.5, borderRadius: BorderRadius.circular(8)),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Conversion Factor', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Equivalent to Base Unit', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: units.asMap().entries.map((entry) {
            final idx = entry.key;
            final u = entry.value;
            final isBase = u.id == 1;
            final equiv = '${u.conversionFactor.toStringAsFixed(4)} $baseCode';

            return DataRow(cells: [
              DataCell(Text('${idx + 1}')),
              DataCell(
                isBase
                    ? Row(children: [
                        Text(u.unit.label),
                        const SizedBox(width: 8),
                        _Badge(label: 'Base Unit', color: AppColors.info),
                      ])
                    : SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<_DropdownOption>(
                          value: u.unit,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: _kBaseUnits
                              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt.label)))
                              .toList(),
                          onChanged: (v) { if (v != null) onUnitChanged(u.id, v); },
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    ? const Text('—', style: TextStyle(color: AppColors.textSecondary))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                            tooltip: 'Edit',
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            tooltip: 'Remove',
                            onPressed: () => onRemoveUnit(u.id),
                          ),
                        ],
                      ),
              ),
            ]);
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
  final String imageUrl;
  final String? category;
  final String? supplier;
  final String price;
  final String currency;
  final _DropdownOption? baseUnit;
  final bool isActive;

  const _ProductPreviewCard({
    required this.name,
    required this.code,
    required this.imageUrl,
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
    final displayCode = code.isEmpty ? 'PRD-XXXX' : code;
    final displayPrice = price.isEmpty ? '—' : '$currency ${double.tryParse(price)?.toStringAsFixed(2) ?? price}';

    return _SectionCard(
      title: 'Live Product Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: double.infinity,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.darkest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.border, size: 40),
                  )
                : const Icon(Icons.image_outlined, color: AppColors.border, size: 40),
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
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(displayCode, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                  const Text('Base Unit  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  _Badge(label: baseUnit!.code.isEmpty ? baseUnit!.label : baseUnit!.code, color: AppColors.info),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
    return _SectionCard(
      title: 'Quick Tips',
      child: Column(
        children: const [
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
            text: 'Use units to define boxes, cartons, and pallets for logistics.',
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
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
      children: children
          .expand((child) => [Expanded(child: child), const SizedBox(width: 14)])
          .toList()
        ..removeLast(),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool fullWidth;

  const _FormField({required this.label, required this.child, this.fullWidth = false});

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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
