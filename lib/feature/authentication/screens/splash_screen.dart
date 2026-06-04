import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

<<<<<<< HEAD


=======
// THAY ĐỔI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI MÁY CỦA BẠN:
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_screen.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/staff_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart';
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  // Hàm kiểm tra xem thiết bị hiện tại có phải là Mobile (Android/iOS) hay không
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
        _isMobile ? context.go('/mobile-login') : context.go('/users', extra: roleId);
      } else if (roleId == 2) {
<<<<<<< HEAD
        _isMobile ? context.go('/mobile-login') : context.go('/dashboard');
      } else if (roleId == 3) {
        _isMobile ? context.go('/driver') : context.go('/login');
      } else if (roleId == 4) {
        context.go('/staff');
=======
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
      } else if (roleId == 4) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StaffScreen()),
        );
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
      } else {
        _navigateToLoginBasedOnDevice();
      }
    } else {
      _navigateToLoginBasedOnDevice();
    }
  }

  void _navigateToLoginBasedOnDevice() {
    if (_isMobile) {
      context.go('/mobile-login');
    } else {
      context.go('/login');
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