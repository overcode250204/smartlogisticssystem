// File: lib/feature/authentication/screens/driver_register_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController =
      TextEditingController(); // THÊM Ô PASS
  bool _isRegistering = false;
  bool _isProcessingAI = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // THUẬT TOÁN AI OCR ĐỌC CHỮ VÀ LỌC REGEX
  Future<void> _processImageOCR(XFile imageFile) async {
    setState(() => _isProcessingAI = true);

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      String fullText = recognizedText.text;

      // 1. Tìm số định danh cá nhân / số bằng lái (Dãy 12 số liên tiếp hoặc 9 số kiểu cũ)
      final idRegex = RegExp(r'\b\d{12}\b|\b\d{9}\b');
      final idMatch = idRegex.stringMatch(fullText);

      // 2. Tìm Họ tên viết hoa (Regex quét các cụm từ viết HOA hoàn toàn có dấu tiếng Việt)
      final nameRegex = RegExp(
        r'\b[A-ZÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸY\s]{5,}\b',
      );
      final List<String> matches = nameRegex
          .allMatches(fullText)
          .map((m) => m.group(0)!.trim())
          .toList();

      String? detectedName;
      for (var text in matches) {
        // Loại bỏ các dòng text hệ thống viết hoa thường gặp trên thẻ CCCD
        if (text.isNotEmpty &&
            !text.contains('CỘNG HÒA') &&
            !text.contains('XÃ HỘI') &&
            !text.contains('VIỆT NAM') &&
            !text.contains('ĐỘC LẬP') &&
            !text.contains('CỤC TRƯỞNG') &&
            !text.contains('THẺ CĂN CƯỚC')) {
          detectedName = text;
          break;
        }
      }

      setState(() {
        if (idMatch != null) _idCardController.text = idMatch;
        if (detectedName != null) _nameController.text = detectedName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đã điền tự động dữ liệu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi quét AI: $e'), backgroundColor: Colors.red),
      );
    } finally {
      textRecognizer.close();
      setState(() => _isProcessingAI = false);
    }
  }

  // HÀM ĐIỀU HƯỚNG MỞ CAMERA THẬT ĐỂ CHỤP ẢNH QUÉT
  void _startCameraScan() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thiết bị Camera vật lý!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Mở màn hình Camera preview lên
    final XFile? capturedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraLivePreviewPage(camera: cameras.first),
      ),
    );

    // Nếu chụp thành công và có ảnh đem đi xử lý OCR
    if (capturedImage != null) {
      _processImageOCR(capturedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký Tài xế mới')),
      body: _isProcessingAI
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'AI đang xử lý hình ảnh và đọc văn bản...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      onPressed: _startCameraScan,
                      icon: const Icon(
                        Icons.document_scanner,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'QUÉT CCCD / BẰNG LÁI (AI OCR)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên tài xế (Tự động điền) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idCardController,
                      decoration: const InputDecoration(
                        labelText: 'Số định danh / Số CCCD (Tự động điền) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên lạc *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Tạo Mật khẩu *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mật khẩu tối thiểu 6 ký tự'
                          : null,
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: _isRegistering
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isRegistering = true);

                                  // GỌI API ĐĂNG KÝ
                                  bool success = await _authService
                                      .registerDriver(
                                        _nameController.text.trim(),
                                        _idCardController.text.trim(),
                                        _phoneController.text.trim(),
                                        _passwordController.text.trim(),
                                      );

                                  setState(() => _isRegistering = false);

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đăng ký thành công! Vui lòng chờ Admin duyệt.',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                    // Quay về màn hình Login
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đăng ký thất bại, vui lòng kiểm tra lại!',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: _isRegistering
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'HOÀN TẤT ĐĂNG KÝ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// CỬA SỔ HIỂN THỊ CAMERA LIVE PREVIEW ĐỂ BẤM CHỤP HÌNH THẬT
class CameraLivePreviewPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraLivePreviewPage({super.key, required this.camera});

  @override
  State<CameraLivePreviewPage> createState() => _CameraLivePreviewPageState();
}

class _CameraLivePreviewPageState extends State<CameraLivePreviewPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Đặt giấy tờ vào khung hình',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(child: CameraPreview(_cameraController));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            // Bấm chụp ảnh vật lý
            final image = await _cameraController.takePicture();
            if (mounted) {
              // Trả file ảnh về cho màn hình Đăng ký
              Navigator.pop(context, image);
            }
          } catch (e) {
            print("Lỗi chụp ảnh: $e");
          }
        },
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}
