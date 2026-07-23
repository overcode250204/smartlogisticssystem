import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/export_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';

class StaffBarcodeExportPage extends StatefulWidget {
  final InventoryBatchBarcodeResponse batch;

  const StaffBarcodeExportPage({super.key, required this.batch});

  @override
  State<StaffBarcodeExportPage> createState() => _StaffBarcodeExportPageState();
}

class StaffBatchDetailPage extends StaffBarcodeExportPage {
  const StaffBatchDetailPage({super.key, required super.batch});
}

class _StaffBarcodeExportPageState extends State<StaffBarcodeExportPage> {
  final ExportService _exportService = ExportService();
  final TextEditingController _quantityController = TextEditingController();
  final DateFormat _displayDateFormatter = DateFormat('yyyy-MM-dd');

  late InventoryBatchBarcodeResponse _batch;
  late DateTime _exportDate;
  String? _quantityError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
    _exportDate = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int? _parseQuantity() {
    return int.tryParse(_quantityController.text.trim());
  }

  bool _validateQuantity() {
    final text = _quantityController.text.trim();
    final quantity = int.tryParse(text);
    String? error;

    if (text.isEmpty) {
      error = 'Vui lòng nhập số lượng xuất';
    } else if (quantity == null || quantity <= 0) {
      error = 'Số lượng xuất phải lớn hơn 0';
    } else if (quantity > _batch.remainingQuantity) {
      error =
          'Số lượng xuất không được vượt quá tồn kho hiện có (${_batch.remainingQuantity})';
    }

    setState(() {
      _quantityError = error;
    });

    return error == null;
  }

  Future<void> _confirmExport() async {
    if (_isSubmitting || !_validateQuantity()) return;

    final quantity = _parseQuantity()!;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedBatch = await _exportService.exportBatch(
        batchId: _batch.batchId,
        quantity: quantity,
        exportDate: _exportDate,
      );

      if (!mounted) return;

      setState(() {
        _batch = updatedBatch;
        _quantityController.clear();
        _quantityError = null;
        _exportDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất hàng thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyExportError(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyExportError(Object error) {
    final message = apiErrorMessage(error);
    final normalized = message.toLowerCase();

    if (normalized.contains('stock') ||
        normalized.contains('tồn') ||
        normalized.contains('insufficient')) {
      return 'Không đủ tồn kho để xuất số lượng này';
    }

    if (normalized.contains('not found') || normalized.contains('không có')) {
      return 'Không tìm thấy lô hàng cần xuất';
    }

    if (message.trim().isEmpty) {
      return 'Không thể xuất hàng. Vui lòng thử lại.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final barcodeImageUrl = _batch.barcodeImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xuất hàng theo barcode',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (barcodeImageUrl != null && barcodeImageUrl.isNotEmpty)
                      Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(
                            barcodeImageUrl,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.qr_code_2,
                                  size: 96,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _batch.productName ?? 'Sản phẩm không xác định',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Barcode: ${_batch.barcode}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 32, color: AppColors.border),
                    _DetailRow(
                      label: 'Số lượng ban đầu',
                      value: _batch.quantity.toString(),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Số lượng còn lại',
                      value: _batch.remainingQuantity.toString(),
                      emphasized: true,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Ngày nhập',
                      value: dateFormatter.format(_batch.importDate),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Ngày hết hạn',
                      value: dateFormatter.format(_batch.expirationDate),
                    ),
                    const SizedBox(height: 24),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày xuất',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _displayDateFormatter.format(_exportDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Số lượng xuất',
                        errorText: _quantityError,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.outbox_outlined),
                      ),
                      onChanged: (_) {
                        if (_quantityError != null) {
                          _validateQuantity();
                        }
                      },
                      onSubmitted: (_) => _confirmExport(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _confirmExport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSubmitting
                              ? 'Đang xuất hàng...'
                              : 'Xác nhận xuất hàng',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: emphasized ? 20 : 16,
              color: emphasized ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
