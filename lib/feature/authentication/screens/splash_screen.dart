import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';




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
        _isMobile ? context.go('/mobile-login') : context.go('/dashboard');
      } else if (roleId == 3) {
        _isMobile ? context.go('/driver') : context.go('/login');
      } else if (roleId == 4) {
        context.go('/staff');
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