import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Màn hình chọn vai trò trước khi đăng nhập.
///
/// Có 2 luồng đăng nhập tách biệt:
/// - Nhân viên (Staff): đăng nhập bằng Email + Mật khẩu  -> `/login`
/// - Tài xế (Driver): đăng nhập bằng Số điện thoại + OTP  -> `/mobile-login`
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping, size: 72, color: Colors.blue),
                  const SizedBox(height: 12),
                  const Text(
                    'SMART LOGISTICS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chọn vai trò để tiếp tục đăng nhập',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    icon: Icons.badge_outlined,
                    title: 'Nhân viên',
                    subtitle: 'Đăng nhập bằng Email và Mật khẩu',
                    color: const Color(0xFF5B4FE9),
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Tài xế',
                    subtitle: 'Đăng nhập bằng Số điện thoại và mã OTP',
                    color: const Color(0xFF2E7D32),
                    onTap: () => context.go('/mobile-login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
