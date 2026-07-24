import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/driver/linehaul_driver/linehaul_driver_navigation.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _driverType = '';

  @override
  void initState() {
    super.initState();
    _checkDriverType();
  }

  Future<void> _checkDriverType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId != null) {
        final response = await _apiClient.get('drivers/by-user/$userId');
        if (response.statusCode == 200 && response.data != null) {
          final resBody = response.data as Map<String, dynamic>;
          final data = resBody['data'] as Map<String, dynamic>?;
          if (data != null) {
            setState(() {
              _driverType = data['driverType']?.toString() ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error checking driver type: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_driverType == 'LINEHAUL') {
      return const LinehaulDriverNavigation();
    }

    // Default screen for other driver types (e.g. Delivery/Local driver)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Tracking GPS'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await _authService.logout();
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
            Text(
              'Màn hình Map Tracking GPS của Tài xế\n(Loại tài xế: $_driverType)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
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
