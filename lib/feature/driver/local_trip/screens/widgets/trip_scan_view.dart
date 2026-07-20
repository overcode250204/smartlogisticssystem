import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_response_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';

class TripScanView extends StatefulWidget {
  final LocalTripResponse trip;
  final Future<void> Function(int detailId, int orderId, String barcode) onScan;
  final VoidCallback onStartExecuting;
  final bool isBusy;

  const TripScanView({
    super.key,
    required this.trip,
    required this.onScan,
    required this.onStartExecuting,
    required this.isBusy,
  });

  @override
  State<TripScanView> createState() => _TripScanViewState();
}

class _TripScanViewState extends State<TripScanView> {
  int? _scanningDetailId;

  Future<void> _handleScan(LocalTripDetailResponse detail) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScanScreen()),
    );
    if (barcode == null || !mounted) return;

    setState(() => _scanningDetailId = detail.id);
    try {
      await widget.onScan(detail.id, detail.order.orderId, barcode);
    } finally {
      if (mounted) setState(() => _scanningDetailId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDetails = [...widget.trip.details]
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
    final allScanned = sortedDetails.every((d) => d.barcodeScanned);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDetails.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final detail = sortedDetails[index];
              final isScanning = _scanningDetailId == detail.id;
              return Card(
                child: ListTile(
                  leading: Icon(
                    detail.barcodeScanned ? Icons.check_circle : Icons.qr_code,
                    color: detail.barcodeScanned
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  title: Text(detail.order.customerName),
                  subtitle: Text(detail.order.orderCode),
                  trailing: detail.barcodeScanned
                      ? const Text(
                          'Đã quét',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                        )
                      : OutlinedButton(
                          onPressed: isScanning ? null : () => _handleScan(detail),
                          child: isScanning
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Quét'),
                        ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (allScanned && !widget.isBusy) ? widget.onStartExecuting : null,
              child: widget.isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Bắt đầu giao hàng'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarcodeScanScreen extends StatefulWidget {
  const _BarcodeScanScreen();

  @override
  State<_BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<_BarcodeScanScreen> {
  bool _handled = false;

  void _finish(String barcode) {
    if (_handled) return;
    _handled = true;
    Navigator.pop(context, barcode);
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;
    _finish(barcode);
  }

  Future<void> _enterManually() async {
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã đơn hàng'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Mã đơn hàng (orderCode)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (barcode != null && barcode.isNotEmpty) {
      _finish(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã đơn hàng'),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
              formats: const [BarcodeFormat.all],
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: FilledButton.icon(
                onPressed: _enterManually,
                icon: const Icon(Icons.keyboard),
                label: const Text('Nhập mã thủ công'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
