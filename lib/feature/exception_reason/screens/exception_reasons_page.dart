import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/exception_reason_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/exception_reason/service/exception_reason_service.dart';

class ExceptionReasonsPage extends StatefulWidget {
  const ExceptionReasonsPage({super.key});

  @override
  State<ExceptionReasonsPage> createState() => _ExceptionReasonsPageState();
}

class _ExceptionReasonsPageState extends State<ExceptionReasonsPage> {
  final ExceptionReasonService _exceptionReasonService = ExceptionReasonService();
  List<ExceptionReasonModel> _reasons = [];
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
      final data = await _exceptionReasonService.getAllExceptionReasons();
      if (mounted) {
        setState(() {
          _reasons = data;
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

  Future<void> _deleteReason(ExceptionReasonModel reason) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa lý do ngoại lệ "${reason.reasonText}" không?',
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
      await _exceptionReasonService.deleteExceptionReason(reason.reasonId);
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

    if (_errorMessage != null && _reasons.isEmpty) {
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
                const Expanded(child: SectionTitle('Danh sách lý do ngoại lệ')),
                ElevatedButton.icon(
                  onPressed: () => _showReasonDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lý do ngoại lệ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_reasons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có lý do ngoại lệ nào',
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
                  DataColumn(label: Text('Mã lý do')),
                  DataColumn(label: Text('Phân loại')),
                  DataColumn(label: Text('Nội dung lý do')),
                  DataColumn(label: Text('Trạng thái hoạt động')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _reasons
                    .map(
                      (reason) => DataRow(
                        cells: [
                          DataCell(Text('ERR${reason.reasonId}')),
                          DataCell(Text(reason.category)),
                          DataCell(Text(reason.reasonText)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: reason.isActive
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                reason.isActive ? 'Đang hoạt động' : 'Đã khóa',
                                style: TextStyle(
                                  color: reason.isActive
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showReasonDialog(context, reason),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteReason(reason),
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

  void _showReasonDialog(BuildContext context, [ExceptionReasonModel? reason]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _ExceptionReasonDialog(
          reason: reason,
          service: _exceptionReasonService,
        );
      },
    ).then((changed) {
      if (changed == true) {
        _loadData();
      }
    });
  }
}

class _ExceptionReasonDialog extends StatefulWidget {
  final ExceptionReasonModel? reason;
  final ExceptionReasonService service;

  const _ExceptionReasonDialog({this.reason, required this.service});

  @override
  State<_ExceptionReasonDialog> createState() => _ExceptionReasonDialogState();
}

class _ExceptionReasonDialogState extends State<_ExceptionReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonTextController = TextEditingController();
  
  String _selectedCategory = 'DELIVERY_FAIL';
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<Map<String, String>> _categories = [
    {'value': 'DELIVERY_FAIL', 'label': 'Thất bại giao hàng (DELIVERY_FAIL)'},
    {'value': 'LINEHAUL_DELAY', 'label': 'Trễ chuyến linehaul (LINEHAUL_DELAY)'},
    {'value': 'WAREHOUSE_DAMAGE', 'label': 'Hư hại kho bãi (WAREHOUSE_DAMAGE)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reason != null) {
      _reasonTextController.text = widget.reason!.reasonText;
      _selectedCategory = widget.reason!.category;
      _isActive = widget.reason!.isActive;
    }
  }

  @override
  void dispose() {
    _reasonTextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.reason == null) {
        final request = ExceptionReasonCreateRequest(
          category: _selectedCategory,
          reasonText: _reasonTextController.text.trim(),
          isActive: _isActive,
        );
        await widget.service.createExceptionReason(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm lý do ngoại lệ thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final request = ExceptionReasonUpdateRequest(
          category: _selectedCategory,
          reasonText: _reasonTextController.text.trim(),
          isActive: _isActive,
        );
        await widget.service.updateExceptionReason(
          widget.reason!.reasonId,
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
        widget.reason == null ? 'Thêm lý do ngoại lệ' : 'Sửa lý do ngoại lệ',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.reason != null) ...[
                TextFormField(
                  initialValue: 'ERR${widget.reason!.reasonId}',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Mã lý do (Read Only)',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Phân loại *',
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['value'],
                    child: Text(cat['label']!),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonTextController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Nội dung lý do *',
                  hintText: 'Nhập nội dung (VD: Khách không nghe máy)',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bắt buộc nhập'
                    : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Trạng thái hoạt động',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: _isActive,
                activeColor: AppColors.success,
                contentPadding: EdgeInsets.zero,
                onChanged: _isSubmitting
                    ? null
                    : (bool val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
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
