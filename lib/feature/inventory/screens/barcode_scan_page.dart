import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/staff_batch_detail_page.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';

class StaffExportScanPage extends StatefulWidget {
  const StaffExportScanPage({super.key});

  @override
  State<StaffExportScanPage> createState() => _StaffExportScanPageState();
}

class BarcodeScanPage extends StaffExportScanPage {
  const BarcodeScanPage({super.key});
}

class _StaffExportScanPageState extends State<StaffExportScanPage> {
  final InventoryBatchService _batchService = InventoryBatchService();
  bool _isLookingUp = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isLookingUp) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isLookingUp = true;
    });

    try {
      final batch = await _batchService.getBatchByBarcode(barcode);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffBarcodeExportPage(batch: batch),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final isNotFound = e is DioException && e.response?.statusCode == 404;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNotFound
                ? 'Không tìm thấy barcode lô hàng'
                : 'Không thể tra cứu barcode. Vui lòng thử lại.',
          ),
          backgroundColor: isNotFound ? AppColors.warning : AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isLookingUp = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quét QR / Barcode xuất hàng',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 1,
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
          if (_isLookingUp)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Đang tra cứu barcode...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
