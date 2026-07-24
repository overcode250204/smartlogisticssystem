import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Danh sách định dạng mã mà scanner hỗ trợ đọc.
/// mobile_scanner 7.x hỗ trợ đầy đủ các định dạng dưới đây trên cả iOS/Android.
const List<BarcodeFormat> kSupportedScanFormats = <BarcodeFormat>[
  BarcodeFormat.qrCode,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
];

/// Mở scanner camera toàn màn hình và trả về mã đã quét (đã trim),
/// hoặc `null` nếu người dùng đóng mà không quét được gì.
///
/// Camera chỉ hoạt động khi modal mở; khi pop, controller được dispose nên
/// camera không chạy nền. Scanner tự khoá sau lần đọc đầu tiên (chống đọc lặp).
Future<String?> scanBarcodeWithCamera(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (_) => const _BarcodeScannerScreen(),
    ),
  );
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: kSupportedScanFormats,
  );

  /// Khoá ngay sau lần đọc đầu tiên để callback không pop nhiều lần.
  bool _handled = false;

  @override
  void dispose() {
    // Đảm bảo camera tắt hẳn khi rời màn hình (không giữ ở background).
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    // Không đổi hoa/thường: giữ nguyên giá trị backend gửi/nhận.
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã đơn hàng'),
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) =>
                _ScannerError(error: error, onClose: () => Navigator.of(context).maybePop()),
          ),
          _ScannerOverlay(),
        ],
      ),
    );
  }
}

/// Khung ngắm + hướng dẫn + trạng thái "Đang quét...".
class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đưa mã barcode hoặc QR vào trong khung',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
              SizedBox(width: 10),
              Text(
                'Đang quét...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hiển thị khi không mở được camera (chủ yếu là bị từ chối quyền).
class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onClose;

  const _ScannerError({required this.error, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            denied ? Icons.no_photography : Icons.error_outline,
            color: Colors.white70,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Ứng dụng chưa được cấp quyền camera.'
                : 'Không mở được camera. Vui lòng thử lại.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (denied) ...[
            const SizedBox(height: 8),
            const Text(
              'Hãy vào Cài đặt → Ứng dụng → cấp quyền Camera, '
              'sau đó mở lại trình quét.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onClose,
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
