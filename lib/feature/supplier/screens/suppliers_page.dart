import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/supplier_request_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/create_supplier_dialog.dart';
import 'package:smartlogisticssystem/feature/supplier/service/supplier_service.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final SupplierService _supplierService = SupplierService();
  List<SupplierResponse> _suppliers = [];
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
      final data = await _supplierService.getAllSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = data;
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

  Future<void> _deleteSupplier(SupplierResponse supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
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

    if (confirm != true) return;

    try {
      await _supplierService.deleteSupplier(supplier.supplierId);
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

    if (_errorMessage != null && _suppliers.isEmpty) {
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
                const Expanded(child: SectionTitle('Danh sách nhà cung cấp')),
                ElevatedButton.icon(
                  onPressed: () => _showSupplierDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm nhà cung cấp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_suppliers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có nhà cung cấp',
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
                  DataColumn(label: Text('Mã NCC')),
                  DataColumn(label: Text('Tên')),
                  DataColumn(label: Text('SĐT')),
                  DataColumn(label: Text('Địa chỉ')),
                  DataColumn(label: Text('Ngày tạo')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _suppliers
                    .map(
                      (supplier) => DataRow(
                        cells: [
                          DataCell(Text('NCC${supplier.supplierId}')),
                          DataCell(Text(supplier.supplierName)),
                          DataCell(Text(supplier.contactPhone ?? '')),
                          DataCell(Text(supplier.address ?? '')),
                          DataCell(
                            Text(
                              supplier.createdAt == null
                                  ? ''
                                  : dateFormatter.format(supplier.createdAt!),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showSupplierDialog(context, supplier),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteSupplier(supplier),
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

  void _showSupplierDialog(BuildContext context, [SupplierResponse? supplier]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _SupplierDialog(
          supplier: supplier,
          supplierService: _supplierService,
        );
      },
    ).then((changed) {
      if (changed == true) {
        _loadData();
      }
    });
  }
}

class _SupplierDialog extends StatefulWidget {
  final SupplierResponse? supplier;
  final SupplierService supplierService;

  const _SupplierDialog({this.supplier, required this.supplierService});

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.supplierName;
      _phoneController.text = widget.supplier!.contactPhone ?? '';
      _addressController.text = widget.supplier!.address ?? '';
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
      if (widget.supplier == null) {
        final request = SupplierCreateRequest(
          supplierName: _nameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
        await widget.supplierService.createSupplier(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm nhà cung cấp thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final request = SupplierUpdateRequest(
          supplierName: _nameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
        await widget.supplierService.updateSupplier(
          widget.supplier!.supplierId,
          request,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
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
      title: Text(
        widget.supplier == null ? 'Thêm nhà cung cấp' : 'Sửa nhà cung cấp',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.supplier != null) ...[
                TextFormField(
                  initialValue: 'NCC${widget.supplier!.supplierId}',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Mã NCC (Read Only)',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Tên nhà cung cấp *',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bắt buộc nhập'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
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
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
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
