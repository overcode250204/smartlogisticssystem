import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/invoice_request_model.dart';
import 'package:smartlogisticssystem/data/model/invoice_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/invoice/services/invoice_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  List<InvoiceResponse> _invoices = [];
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
      final data = await _invoiceService.getAllInvoices();
      if (mounted) {
        setState(() {
          _invoices = data;
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

  Future<void> _deleteInvoice(InvoiceResponse invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa hóa đơn #${invoice.invoiceId} không?',
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
      await _invoiceService.deleteInvoice(invoice.invoiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa hóa đơn thành công'),
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

    if (_errorMessage != null && _invoices.isEmpty) {
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
                const Expanded(child: SectionTitle('Danh sách hóa đơn')),
                ElevatedButton.icon(
                  onPressed: () => _showInvoiceDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm hóa đơn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có hóa đơn',
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
                  DataColumn(label: Text('Mã HĐ')),
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Số tiền')),
                  DataColumn(label: Text('Người tạo')),
                  DataColumn(label: Text('Ngày tạo')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _invoices
                    .map(
                      (invoice) => DataRow(
                        cells: [
                          DataCell(Text('HĐ${invoice.invoiceId}')),
                          DataCell(_InvoiceTypeBadge(invoice.invoiceType)),
                          DataCell(
                            Text(currencyFormatter.format(invoice.totalAmount)),
                          ),
                          DataCell(Text(invoice.createdByName)),
                          DataCell(
                            Text(
                              invoice.createdAt == null
                                  ? ''
                                  : dateFormatter.format(invoice.createdAt!),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showInvoiceDialog(context, invoice),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteInvoice(invoice),
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

  void _showInvoiceDialog(BuildContext context, [InvoiceResponse? invoice]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InvoiceDialog(
        invoice: invoice,
        invoiceService: _invoiceService,
      ),
    ).then((changed) {
      if (changed == true) _loadData();
    });
  }
}

// ─── Type badge ───────────────────────────────────────────────────────────────

class _InvoiceTypeBadge extends StatelessWidget {
  final String type;
  const _InvoiceTypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final isImport = type.toLowerCase() == 'import';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isImport ? AppColors.primary : AppColors.warning)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isImport ? 'Nhập' : 'Xuất',
        style: TextStyle(
          color: isImport ? AppColors.primary : AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Create / Edit dialog ─────────────────────────────────────────────────────

class _InvoiceDialog extends StatefulWidget {
  final InvoiceResponse? invoice;
  final InvoiceService invoiceService;

  const _InvoiceDialog({this.invoice, required this.invoiceService});

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _createdByController = TextEditingController();

  String _selectedType = 'Import';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _types = ['Import', 'Export'];

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _selectedType = widget.invoice!.invoiceType;
      _amountController.text = widget.invoice!.totalAmount.toString();
      _createdByController.text = widget.invoice!.createdById.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final createdById = int.parse(_createdByController.text.trim());

      if (widget.invoice == null) {
        await widget.invoiceService.createInvoice(
          InvoiceCreateRequest(
            invoiceType: _selectedType,
            totalAmount: amount,
            createdById: createdById,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm hóa đơn thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await widget.invoiceService.updateInvoice(
          widget.invoice!.invoiceId,
          InvoiceUpdateRequest(
            invoiceType: _selectedType,
            totalAmount: amount,
            createdById: createdById,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật hóa đơn thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
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
        widget.invoice == null ? 'Thêm hóa đơn' : 'Sửa hóa đơn',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.invoice != null) ...[
                TextFormField(
                  initialValue: 'HĐ${widget.invoice!.invoiceId}',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Mã hóa đơn (Read Only)',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _selectedType, // ignore: deprecated_member_use
                decoration: const InputDecoration(labelText: 'Loại hóa đơn *'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bắt buộc nhập';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _createdByController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID người tạo *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bắt buộc nhập';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Phải là số nguyên';
                  }
                  return null;
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
          onPressed:
              _isSubmitting ? null : () => Navigator.pop(context, false),
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
