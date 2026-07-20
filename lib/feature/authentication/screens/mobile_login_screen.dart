import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_register_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final AuthService _authService = AuthService();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false; // Trạng thái kiểm tra đã gửi OTP hay chưa
  String?
  _sessionInfo; // Lúc này đóng vai trò là verificationId nhận từ Firebase SDK
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // =================================================================
  // LUỒNG XỬ LÝ: GỬI MÃ OTP ĐẾN SỐ ĐIỆN THOẠI THẬT (DÙNG SDK)
  // =================================================================
  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = 'Vui lòng nhập số điện thoại hợp lệ!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 🚀 ĐÃ SỬA: Gọi hàm SDK mới để kích hoạt gửi SMS thật về máy
    await _authService.sendOtpToRealPhone(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        // Callback kích hoạt khi Google gửi tin nhắn thành công
        setState(() {
          _isLoading = false;
          _sessionInfo = verificationId;
          _isOtpSent = true;
        });
      },
      onFailed: (errorMsg) {
        // Callback kích hoạt khi xảy ra lỗi (Sai định dạng, reCAPTCHA chặn...)
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      },
    );
  }

  // =================================================================
  // LUỒNG XỬ LÝ: XÁC THỰC MÃ OTP SMS VÀ ĐĂNG NHẬP
  // =================================================================
  Future<void> _handleVerifyOtpAndLogin() async {
    final otp = _otpController.text.trim();
    final phone = _phoneController.text.trim();

    if (otp.isEmpty || _sessionInfo == null) {
      setState(() => _errorMessage = 'Vui lòng nhập mã OTP gồm 6 số!');
      return;
    }

    setState(() => _isLoading = true);

    // 🚀 ĐÃ SỬA: Gọi hàm verify đổi OTP lấy Token thông qua Firebase SDK mới
    final loginResult = await _authService.verifyOtpAndLoginV2(
      verificationId: _sessionInfo!,
      otpCode: otp,
      phoneNumber: phone,
    );

    setState(() => _isLoading = false);

    if (loginResult != null) {
      final roleId = loginResult['roleId']!;
      final userId = loginResult['userId']!;
      final bool isActive = loginResult['isActive'] ?? false;

      // Chặn nếu tài xế mới tự tạo tài khoản chưa được Quản trị viên duyệt
      if (!isActive) {
        setState(() {
          _errorMessage = 'Tài khoản tài xế đang chờ Admin phê duyệt!';
        });
        return;
      }

      // KIỂM TRA PHÂN QUYỀN THIẾT BỊ (DRIVER VÀ STAFF ĐƯỢC VÀO MOBILE)
      if (roleId == 3 || roleId == 4) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('roleId', roleId);
        await prefs.setInt('userId', userId);
        await prefs.setString('fullName', loginResult['fullName']?.toString() ?? 'Người dùng');
        await prefs.setString('email', loginResult['email']?.toString() ?? '');
        await prefs.setString('roleName', loginResult['roleName']?.toString() ?? 'N/A');

        if (mounted) {
          if (roleId == 3) {
            context.go('/driver');
          } else {
            context.go('/staff');
          }
        }
      } else {
        // CHẶN ADMIN HOẶC THỦ KHO ĐĂNG NHẬP TRÊN MOBILE
        setState(() {
          _errorMessage = 'Vui lòng đăng nhập trên máy tính Desktop!';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Mã OTP không chính xác hoặc lỗi hệ thống backend!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Logistics Mobile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo hệ thống vận tải
                      const Icon(
                        Icons.local_shipping,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SMART LOGISTICS',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'Hệ thống tổng đài dành cho Tài xế',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Khu vực hiển thị thông báo lỗi trực quan
                      if (_errorMessage.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Ô nhập Số điện thoại tài xế
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isOtpSent,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại tài xế',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: 'Ví dụ: 0912345678',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Giao diện động: Xuất hiện ô nhập OTP sau khi đã gửi thành công
                      if (_isOtpSent) ...[
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Mã xác thực OTP (6 số)',
                            prefixIcon: Icon(Icons.lock_clock),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _handleVerifyOtpAndLogin,
                            child: const Text(
                              'XÁC NHẬN & VÀO ỨNG DỤNG',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Nút bấm gửi OTP lần đầu
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _handleSendOtp,
                            child: const Text(
                              'GỬI MÃ OTP XÁC THỰC',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Nút chuyển hướng sang màn hình Đăng ký tài xế mới
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DriverRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Chưa có tài khoản? Đăng ký tài xế mới tại đây',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
