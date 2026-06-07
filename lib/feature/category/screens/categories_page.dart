import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/category/service/category_service.dart';
import 'package:smartlogisticssystem/feature/category/screens/create_category_dialog.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  List<ProductCategoryResponse> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = apiErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(ProductCategoryResponse category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
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

    if (confirm != true) return;

    try {
      await _categoryService.deleteCategory(category.categoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${apiErrorMessage(e)}'),
          backgroundColor: AppColors.danger,
        ),
      );
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

    if (_errorMessage != null && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return PageScroll(
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle('Danh sách danh mục')),
                ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm danh mục'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có danh mục nào',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              DarkTable(
                columns: const [
                  DataColumn(label: Text('ID Danh mục')),
                  DataColumn(label: Text('Mã danh mục')),
                  DataColumn(label: Text('Tên danh mục')),
                  DataColumn(label: Text('Mô tả')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _categories
                    .map(
                      (category) => DataRow(
                        cells: [
                          DataCell(Text(category.categoryId.toString())),
                          DataCell(Text(category.categoryCode)),
                          DataCell(Text(category.categoryName)),
                          DataCell(Text(category.description ?? '')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showCategoryDialog(context, category),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteCategory(category),
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppColors.danger,
                                ),
                              ],
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
    );
  }

  void _showCategoryDialog(BuildContext context, [ProductCategoryResponse? category]) {
    if (category == null) {
      showDialog<ProductCategoryResponse>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CreateCategoryDialog(),
      ).then((newCategory) {
        if (newCategory != null) {
          _loadData();
        }
      });
    } else {
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _EditCategoryDialog(
            category: category,
            categoryService: _categoryService,
          );
        },
      ).then((changed) {
        if (changed == true) {
          _loadData();
        }
      });
    }
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final ProductCategoryResponse category;
  final CategoryService categoryService;

  const _EditCategoryDialog({
    required this.category,
    required this.categoryService,
  });

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.categoryName;
    _descriptionController.text = widget.category.description ?? '';
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
      final request = ProductCategoryCreateRequest(
        categoryCode: widget.category.categoryCode, // Keep existing code
        categoryName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      
      await widget.categoryService.updateCategory(
        widget.category.categoryId,
        request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = apiErrorMessage(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Sửa danh mục'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.category.categoryId.toString(),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'ID (Read Only)',
                ),
              ),
              const SizedBox(height: 12),
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
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: AppColors.danger.withValues(alpha: 0.1),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
