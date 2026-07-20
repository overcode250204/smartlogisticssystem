import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String _fullName = '';
  String _email = '';
  String _roleName = '';
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fullName = prefs.getString('fullName') ?? 'Khách hàng';
        _email = prefs.getString('email') ?? '';
        _roleName = prefs.getString('roleName') ?? 'Khách hàng';
        _userId = prefs.getInt('userId') ?? 0;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.danger, foregroundColor: Colors.white),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tài khoản', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
          const SizedBox(height: 20),

          // Profile card
          CustomerCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: CustomerColors.primary,
                  child: Text(
                    _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'K',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(_email, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_roleName, style: const TextStyle(color: CustomerColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info section
          CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
                const SizedBox(height: 12),
                _ProfileItem(icon: Icons.person_outline, label: 'Họ và tên', value: _fullName),
                _ProfileItem(icon: Icons.email_outlined, label: 'Email', value: _email),
                _ProfileItem(icon: Icons.badge_outlined, label: 'Mã người dùng', value: '#$_userId'),
                _ProfileItem(icon: Icons.work_outline, label: 'Vai trò', value: _roleName),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick nav
          CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: CustomerColors.textPrimary)),
                const SizedBox(height: 8),
                _QuickNav(icon: Icons.receipt_long_outlined, label: 'Đơn hàng của tôi', onTap: () => context.go('/customer/orders')),
                _QuickNav(icon: Icons.shopping_cart_outlined, label: 'Giỏ hàng', onTap: () => context.go('/customer/cart')),
                _QuickNav(icon: Icons.inventory_2_outlined, label: 'Sản phẩm', onTap: () => context.go('/customer/products')),
                _QuickNav(icon: Icons.home_outlined, label: 'Trang chủ', onTap: () => context.go('/customer')),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: CustomerColors.danger),
              label: const Text('Đăng xuất', style: TextStyle(color: CustomerColors.danger, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CustomerColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CustomerColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: CustomerColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }
}

class _QuickNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNav({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      leading: Icon(icon, color: CustomerColors.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: CustomerColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: CustomerColors.textSecondary),
      onTap: onTap,
    );
  }
}
