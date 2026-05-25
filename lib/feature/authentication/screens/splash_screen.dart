// File: lib/features/auth_nguyen/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// THAY ĐỔI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI MÁY CỦA BẠN:
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart';

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
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final roleId = prefs.getInt('roleId');

    if (!mounted) return;

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
            builder: (context) => const InventoryManagementScreen(),
          ),
        );
      } else if (roleId == 3) {
        // ĐÃ SỬA: Đưa vào màn hình DriverScreen có nút Logout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // ĐÃ SỬA: Chỉ cần gọi LoginScreen, bên trong file đó sẽ tự check Mobile/Desktop
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
