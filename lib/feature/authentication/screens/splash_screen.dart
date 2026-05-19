// File: lib/features/auth_nguyen/splash_screen.dart
import 'dart:io' show Platform; // Thêm thư viện này để check hệ điều hành
import 'package:flutter/foundation.dart'
    show kIsWeb; // Thêm thư viện này để check Web
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';

// THAY ĐỔI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI MÁY CỦA BẠN:
import 'package:smartlogisticssystem/feature/authentication/screens/mobile_login_screen.dart';
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart'; // Màn hình Login Mobile

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Chờ 1.5 giây cho người dùng nhìn thấy Logo App
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final roleId = prefs.getInt('roleId');

    if (!mounted) return;

    // TRƯỜNG HỢP 1: ĐÃ ĐĂNG NHẬP (AUTO-LOGIN)
    if (roleId != null) {
      if (roleId == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserListScreen(currentRoleId: roleId),
          ),
        );
      } else if (roleId == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Màn hình Quản lý Kho của Bảo')),
            ),
          ),
        );
      } else if (roleId == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Màn hình Map Tracking GPS của Tài xế')),
            ),
          ),
        );
      } else {
        _routeToLogin(); // Quyền rác -> Trục xuất ra Login
      }
    }
    // TRƯỜNG HỢP 2: CHƯA ĐĂNG NHẬP -> CHỌN MÀN HÌNH LOGIN THEO THIẾT BỊ
    else {
      _routeToLogin();
    }
  }

  // HÀM PHÂN LUỒNG MÀN HÌNH LOGIN (DESKTOP HAY MOBILE)
  void _routeToLogin() {
    // Kiểm tra xem có phải đang chạy trên điện thoại không?
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (isMobile) {
      // 1. NẾU LÀ ĐIỆN THOẠI -> Mở màn hình Login có nút Đăng ký OCR
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MobileLoginScreen()),
      );
    } else {
      // 2. NẾU LÀ MÁY TÍNH/WEB -> Mở màn hình Login tiêu chuẩn của Admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Smart Logistics ERP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
