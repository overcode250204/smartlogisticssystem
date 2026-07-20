// File: lib/feature/driver/driver_screens/driver_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';

// SỬA ĐƯỜNG DẪN IMPORT NÀY NẾU CẦN:
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Tracking GPS'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // NÚT ĐĂNG XUẤT CHO TÀI XẾ
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Màn hình Map Tracking GPS của Tài xế\n(Task của Đức)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/driver/local-trips'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Đơn giao hàng nội thành'),
            ),
          ],
        ),
      ),
    );
  }
}
