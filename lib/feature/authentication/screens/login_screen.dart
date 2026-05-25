import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_register_screen.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formValidate = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _errorMessage = '';

  void _handleLogin() async {
    if (!_formValidate.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    Map<String, int>? loginResult = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (loginResult != null) {
      int roleId = loginResult['roleId']!;
      int userId = loginResult['userId']!;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('roleId', roleId);
      await prefs.setInt('userId', userId);

      // KIỂM TRA THIẾT BỊ ĐANG CHẠY LÀ GÌ?
      // kIsWeb là false (nghĩa là ko chạy trên trình duyệt) VÀ chạy trên Android hoặc iOS
      bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

      if (roleId == 1 || roleId == 2) {
        // ==========================================
        // NHÓM QUẢN TRỊ (ADMIN = 1, THỦ KHO = 2)
        // ==========================================
        if (isMobile) {
          setState(() {
            _errorMessage =
                'Tài khoản quản trị. Vui lòng đăng nhập trên máy tính Desktop!';
          });
          await _authService.logout(); // Xóa phiên đăng nhập sai thiết bị
        } else {
          // HỢP LỆ: Đang dùng Desktop
          if (mounted) {
            if (roleId == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserListScreen(currentRoleId: roleId),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryManagementScreen(),
                ),
              );
            }
          }
        }
      } else if (roleId == 3) {
        if (isMobile) {
          if (isMobile) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DriverScreen()),
              );
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Tài xế vui lòng đăng nhập trên ứng dụng Mobile.';
          });
          await _authService.logout();
        }
      } else {
        setState(() {
          _errorMessage = 'Quyền truy cập không hợp lệ!';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Email hoặc mật khẩu không chính xác!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          // 2. BỌC COLUMN TRONG FORM
          child: Form(
            key: _formValidate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đăng nhập Hệ thống',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // 3. ĐỔI THÀNH TextFormField ĐỂ KIỂM TRA EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. ĐỔI THÀNH TextFormField ĐỂ KIỂM TRA MẬT KHẨU
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải từ 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                if (isMobile) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverRegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Chưa có tài khoản? Đăng ký tài xế mới',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
