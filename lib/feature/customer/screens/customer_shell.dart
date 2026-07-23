import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';

/// Color palette for Customer Portal
class CustomerColors {
  static const primary = Color(0xFF1E40AF); // Deep blue
  static const primaryLight = Color(0xFF3B82F6); // Bright blue
  static const primaryDark = Color(0xFF1E3A8A);
  static const accent = Color(0xFF0EA5E9); // Sky blue accent
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF1F5F9);
  static const sidebar = Color(0xFF1E40AF);
  static const sidebarText = Color(0xFFBFDBFE);
  static const sidebarTextActive = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);
}

class CustomerShell extends StatefulWidget {
  final Widget child;
  final String location;

  const CustomerShell({super.key, required this.child, required this.location});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  String _fullName = '';
  final AuthService _authService = AuthService();
  int _cartCount = 0;

  static const _navItems = [
    _NavItem('/customer', Icons.home_outlined, Icons.home, 'Trang chủ'),
    _NavItem('/customer/products', Icons.inventory_2_outlined, Icons.inventory_2, 'Sản phẩm'),
    _NavItem('/customer/cart', Icons.shopping_cart_outlined, Icons.shopping_cart, 'Giỏ hàng'),
    _NavItem('/customer/orders', Icons.receipt_long_outlined, Icons.receipt_long, 'Đơn hàng'),
    _NavItem('/customer/profile', Icons.person_outline, Icons.person, 'Tài khoản'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _refreshCartCount();
  }

  @override
  void didUpdateWidget(CustomerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _refreshCartCount();
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthSession.getCurrentUser();
    if (mounted) {
      setState(() {
        _fullName = user?.displayName ?? 'Khách hàng';
      });
    }
  }

  Future<void> _refreshCartCount() async {
    await CartService.instance.load();
    if (widget.location == '/customer/cart' || widget.location == '/customer/checkout') {
      await CartService.instance.markCartAsSeen();
    }
    if (mounted) {
      setState(() {
        _cartCount = CartService.instance.notificationCount;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) context.go('/login');
  }

  bool _isActive(String route) {
    if (route == '/customer') return widget.location == '/customer';
    return widget.location.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: CustomerColors.background,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Column(
        children: [
          _buildHeader(context, isMobile),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) _buildSidebar(context),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: CustomerColors.surface,
        border: Border(bottom: BorderSide(color: CustomerColors.border)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
        child: Row(
          children: [
            if (isMobile)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: CustomerColors.primary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            // Logo
            GestureDetector(
              onTap: () => context.go('/customer'),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CustomerColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  if (!isMobile)
                    const Text(
                      'SmartLogistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Search bar
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
                child: GestureDetector(
                  onTap: () => context.go('/customer/products'),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: CustomerColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CustomerColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, size: 18, color: CustomerColors.textSecondary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tìm kiếm sản phẩm...',
                            style: TextStyle(color: CustomerColors.textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Cart badge
            Stack(
              children: [
                IconButton(
                  onPressed: () => context.go('/customer/cart'),
                  icon: const Icon(Icons.shopping_cart_outlined, color: CustomerColors.primary),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: CustomerColors.danger,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          _cartCount > 99 ? '99+' : '$_cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Avatar + name
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: CustomerColors.primary,
                    child: Text(
                      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'K',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text(
                      _fullName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CustomerColors.textPrimary),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: CustomerColors.textSecondary),
                  ],
                ],
              ),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 8), Text('Tài khoản')])),
                const PopupMenuItem(value: 'orders', child: Row(children: [Icon(Icons.receipt_long_outlined, size: 18), SizedBox(width: 8), Text('Đơn hàng của tôi')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: CustomerColors.danger), SizedBox(width: 8), Text('Đăng xuất', style: TextStyle(color: CustomerColors.danger))])),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'profile': context.go('/customer/profile'); break;
                  case 'orders': context.go('/customer/orders'); break;
                  case 'logout': _logout(context); break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: CustomerColors.sidebar,
        border: Border(right: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          ..._navItems.map((item) => _SidebarTile(
            item: item,
            isActive: _isActive(item.route),
            cartCount: item.route == '/customer/cart' ? _cartCount : 0,
            onTap: () => context.go(item.route),
          )),
          const Spacer(),
          const Divider(color: Color(0x33FFFFFF)),
          _SidebarTile(
            item: const _NavItem('/logout', Icons.logout_outlined, Icons.logout, 'Đăng xuất'),
            isActive: false,
            cartCount: 0,
            onTap: () => _logout(context),
            isDanger: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: CustomerColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                const Text('SmartLogistics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._navItems.map((item) => _SidebarTile(
            item: item,
            isActive: _isActive(item.route),
            cartCount: item.route == '/customer/cart' ? _cartCount : 0,
            onTap: () {
              Navigator.pop(context);
              context.go(item.route);
            },
          )),
          const Spacer(),
          const Divider(color: Color(0x33FFFFFF)),
          _SidebarTile(
            item: const _NavItem('/logout', Icons.logout_outlined, Icons.logout, 'Đăng xuất'),
            isActive: false,
            cartCount: 0,
            onTap: () {
              Navigator.pop(context);
              _logout(context);
            },
            isDanger: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: CustomerColors.border)),
      ),
      child: Row(
        children: _navItems.take(5).map((item) {
          final active = _isActive(item.route);
          return Expanded(
            child: InkWell(
              onTap: () => context.go(item.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Icon(active ? item.activeIcon : item.icon,
                          color: active ? CustomerColors.primary : CustomerColors.textSecondary, size: 22),
                        if (item.route == '/customer/cart' && _cartCount > 0)
                          Positioned(
                            right: -2, top: -2,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(color: CustomerColors.danger, borderRadius: BorderRadius.circular(7)),
                              child: Center(child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.label, style: TextStyle(fontSize: 10, color: active ? CustomerColors.primary : CustomerColors.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final int cartCount;
  final VoidCallback onTap;
  final bool isDanger;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.cartCount,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isDanger
                      ? const Color(0xFFFCA5A5)
                      : isActive
                          ? Colors.white
                          : CustomerColors.sidebarText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isDanger
                          ? const Color(0xFFFCA5A5)
                          : isActive
                              ? Colors.white
                              : CustomerColors.sidebarText,
                    ),
                  ),
                ),
                if (cartCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CustomerColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable widgets
class CustomerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const CustomerCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerColors.border),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class CustomerStatusBadge extends StatelessWidget {
  final String status;

  const CustomerStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (text, color, bg) = _statusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  static (String, Color, Color) _statusData(String status) {
    return switch (status.toUpperCase()) {
      'NEW' => ('Mới', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
      'CONFIRMED' => ('Xác nhận', const Color(0xFF0369A1), const Color(0xFFE0F2FE)),
      'PROCESSING' => ('Xử lý', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
      'IN_TRANSIT' || 'INTRANSIT' => ('Đang giao', const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
      'DELIVERED' => ('Đã giao', const Color(0xFF059669), const Color(0xFFD1FAE5)),
      'COMPLETED' => ('Hoàn thành', const Color(0xFF065F46), const Color(0xFFD1FAE5)),
      'CANCELLED' => ('Đã hủy', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _ => (status, const Color(0xFF374151), const Color(0xFFF3F4F6)),
    };
  }
}

class CustomerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const CustomerEmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CustomerColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: CustomerColors.textSecondary)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class CustomerErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomerErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: CustomerColors.danger),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: CustomerColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: CustomerColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
