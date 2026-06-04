import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/camera_live_preview_page.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isRegistering = false;
  bool _isProcessingAI = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _originController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _removeDiacritics(String str) {
    const withDia =
        'ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬĐÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸYáàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹy';
    const withoutDia =
        'AAAAAAAAAAAAAAAAADEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYaaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    String result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  String _extractValueAfterKeyword(String rawLine, List<String> keywords) {
    String lowerLine = rawLine.toLowerCase();
    int lastIndex = -1;
    for (String kw in keywords) {
      int idx = lowerLine.lastIndexOf(kw.toLowerCase());
      if (idx != -1) {
        int endIdx = idx + kw.length;
        if (endIdx > lastIndex) lastIndex = endIdx;
      }
    }
    if (lastIndex != -1) {
      String value = rawLine.substring(lastIndex);
      return value.replaceAll(RegExp(r'^[\s:;\|l\/]+'), '').trim();
    }
    return rawLine;
  }

  // THUẬT TOÁN AI OCR - PHIÊN BẢN CHẶT TỪ KHÓA
  Future<void> _processImageOCR(XFile imageFile) async {
    setState(() => _isProcessingAI = true);

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      String fullText = recognizedText.text;

      print("=== AI TEXT RAW ===");
      print(fullText);

      final idRegex = RegExp(r'\b\d{12}\b|\b\d{9}\b');
      final idMatch = idRegex.stringMatch(fullText);

      String? detectedName;
      String? detectedOrigin;
      String? detectedAddress;

      List<String> lines = fullText.split('\n');

      List<String> blackListNoAccent = [
        'CONG HOA',
        'XA HOI',
        'VIET NAM',
        'CAN CUOC',
        'CONG DAN',
        'GIAY PHEP',
        'LAI XE',
        'HO VA TEN',
        'BO CONG AN',
        'GIAM DOC',
        'INDEPENDENCE',
        'REPUBLIC',
        'SOCIALIST',
        'NATIONALITY',
        'SEX',
        'DATE',
        'BIRTH',
        'CITIZEN',
      ];

      for (int i = 0; i < lines.length; i++) {
        String rawLine = lines[i].trim();
        if (rawLine.isEmpty) continue;

        String upperLine = rawLine.toUpperCase();
        String cleanLineNoAccent = _removeDiacritics(upperLine);

        // ==========================================
        // 1. TÌM QUÊ QUÁN
        // ==========================================
        if (cleanLineNoAccent.contains('QUE QUAN') ||
            cleanLineNoAccent.contains('NGUYEN QUAN') ||
            cleanLineNoAccent.contains('ORIGIN')) {
          // Dùng vũ khí mới: Chặt ngay sau chữ 'origin', 'quán', hoặc 'quản'
          String tempAddress = _extractValueAfterKeyword(rawLine, [
            'origin',
            'quán',
            'quan',
            'quản',
            'sinh',
          ]);

          for (int j = i + 1; j <= i + 2 && j < lines.length; j++) {
            String nextLine = lines[j].trim();
            String nextLineNoAccent = _removeDiacritics(nextLine.toUpperCase());

            if (nextLineNoAccent.contains('THUONG TRU') ||
                nextLineNoAccent.contains('CU TRU') ||
                nextLineNoAccent.contains('RESIDENCE'))
              break;
            if (!nextLine.toUpperCase().contains('PLACE OF')) {
              tempAddress = tempAddress.isEmpty
                  ? nextLine
                  : "$tempAddress, $nextLine";
            }
          }
          detectedOrigin = tempAddress;
        }

        // ==========================================
        // 2. TÌM NƠI THƯỜNG TRÚ
        // ==========================================
        if (cleanLineNoAccent.contains('THUONG TRU') ||
            cleanLineNoAccent.contains('CU TRU') ||
            cleanLineNoAccent.contains('RESIDENCE')) {
          // Dùng vũ khí mới: Chặt ngay sau chữ 'residence', 'trú', hoặc 'tru'
          String tempAddress = _extractValueAfterKeyword(rawLine, [
            'residence',
            'trú',
            'tru',
          ]);

          for (int j = i + 1; j <= i + 2 && j < lines.length; j++) {
            String nextLine = lines[j].trim();
            String nextLineNoAccent = _removeDiacritics(nextLine.toUpperCase());

            if (nextLineNoAccent.contains('CO GIA TRI') ||
                nextLineNoAccent.contains('DAC DIEM') ||
                nextLineNoAccent.contains('EXPIRY') ||
                nextLineNoAccent.contains('DATE') ||
                RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(nextLine.toUpperCase()))
              break;
            if (!nextLine.toUpperCase().contains('PLACE OF')) {
              tempAddress = tempAddress.isEmpty
                  ? nextLine
                  : "$tempAddress, $nextLine";
            }
          }
          detectedAddress = tempAddress;
        }

        // ==========================================
        // 3. TÌM HỌ TÊN CHỐNG NHIỄU (ALL CAPS)
        // ==========================================
        if (detectedName == null && rawLine == upperLine) {
          bool isTrash = blackListNoAccent.any(
            (badWord) => cleanLineNoAccent.contains(badWord),
          );
          if (!isTrash) {
            final nameRegex = RegExp(
              r'^[A-ZÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸY\s]+$',
            );
            if (nameRegex.hasMatch(rawLine)) {
              int wordCount = rawLine
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .length;
              if (wordCount >= 2 && wordCount <= 6) {
                detectedName = rawLine;
              }
            }
          }
        }
      }

      String cleanAddress(String? text) {
        if (text == null) return "";
        return text
            .replaceAll(RegExp(r'^[,:\-\s]+|[,:\-\s]+$'), '')
            .replaceAll(', ,', ', ')
            .replaceAll(' ,', ',')
            .trim();
      }

      setState(() {
        if (idMatch != null) _idCardController.text = idMatch;
        if (detectedName != null) _nameController.text = detectedName;
        if (detectedOrigin != null && detectedOrigin!.isNotEmpty)
          _originController.text = cleanAddress(detectedOrigin);
        if (detectedAddress != null && detectedAddress!.isNotEmpty)
          _addressController.text = cleanAddress(detectedAddress);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đã quét CCCD thành công!'),
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

  void _startCameraScan() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thiết bị Camera vật lý!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final XFile? capturedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraLivePreviewPage(camera: cameras.first),
      ),
    );

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
                    'AI đang đọc toàn bộ CCCD của bạn...',
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
                        'QUÉT CCCD (TỰ ĐIỀN ĐỊA CHỈ)',
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idCardController,
                      decoration: const InputDecoration(
                        labelText: 'Số định danh / Số CCCD *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ô NHẬP QUÊ QUÁN
                    TextFormField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Quê quán (Nguyên quán) *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2, // Cho phép hiển thị 2 dòng
                    ),
                    const SizedBox(height: 16),

                    // Ô NHẬP ĐỊA CHỈ THƯỜNG TRÚ
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Nơi thường trú *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2, // Cho phép hiển thị 2 dòng
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên lạc *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 16),

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
                                  UserModel userDTO = UserModel(
                                    fullName: _nameController.text.trim(),
                                    roleId: 3,
                                    roleName: 'Driver',
                                    phone: _phoneController.text.trim(),
                                    isActive: true,
                                    identificationNumber: _idCardController.text.trim(),
                                    password: _passwordController.text.trim(),
                                    origin: _originController.text.trim(),
                                    address: _addressController.text.trim(),
                                  );

                                  setState(() => _isRegistering = true);

                                  bool success = await _authService
                                      .registerDriver(userDTO);

                                  setState(() => _isRegistering = false);

                                  if (success) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đăng ký thành công! Vui lòng chờ Admin duyệt.',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đăng ký thất bại, vui lòng kiểm tra lại!',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
