import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_status.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';

class BatchDetailPage extends StatefulWidget {
  final InventoryBatchBarcodeResponse batch;

  const BatchDetailPage({super.key, required this.batch});

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> {
  late InventoryBatchBarcodeResponse _batch;
  final InventoryBatchService _batchService = InventoryBatchService();
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _batch = widget.batch;
  }

  Future<void> _confirmReceived() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhận hàng'),
        content: const Text('Bạn chắc chắn đã nhận lô hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
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

    if (confirm != true) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      await _batchService.confirmReceived(_batch.batchId);
      final updatedBatch = await _batchService.getBatchByBarcode(
        _batch.barcode,
      );

      if (!mounted) return;

      setState(() {
        _batch = updatedBatch;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận đã nhận hàng thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final barcodeImageUrl = _batch.barcodeImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết lô hàng',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (barcodeImageUrl != null && barcodeImageUrl.isNotEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(
                            barcodeImageUrl,
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.qr_code,
                              size: 100,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _batch.productName ?? 'Sản phẩm không xác định',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã vạch: ${_batch.barcode}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 32, color: AppColors.border),
                    _DetailRow(
                      label: 'Trạng thái',
                      value: _batch.status.label,
                      status: _batch.status,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Số lượng ban đầu',
                      value: _batch.quantity.toString(),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Số lượng tồn',
                      value: _batch.remainingQuantity.toString(),
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
                    if (_batch.received)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đã nhận hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isConfirming ? null : _confirmReceived,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isConfirming
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Xác nhận đã nhận hàng',
                            style: TextStyle(
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
  final InventoryBatchStatus? status;

  const _DetailRow({required this.label, required this.value, this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == null ? null : _getStatusColor(status!);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (color != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(InventoryBatchStatus status) {
    switch (status) {
      case InventoryBatchStatus.OUT_OF_STOCK:
        return AppColors.danger;
      case InventoryBatchStatus.EXPIRING_SOON:
      case InventoryBatchStatus.LOW_STOCK:
        return AppColors.warning;
      case InventoryBatchStatus.GOOD:
      case InventoryBatchStatus.NORMAL:
        return AppColors.success;
    }
  }
}
