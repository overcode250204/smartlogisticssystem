import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';

class SidebarItem {
  final String label;
  final String route;
  final IconData icon;
  final Set<int>? allowedRoleIds;

  const SidebarItem({
    required this.label,
    required this.route,
    required this.icon,
    this.allowedRoleIds,
  });
}

class Sidebar extends StatelessWidget {
  final String currentLocation;
  final Future<int?> roleIdFuture;
  final ValueChanged<String> onNavigate;

  const Sidebar({
    super.key,
    required this.currentLocation,
    required this.roleIdFuture,
    required this.onNavigate,
  });

  static const items = [
    SidebarItem(
      label: 'Tổng quan',
      route: '/dashboard',
      icon: Icons.home_outlined,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Quản lý kho',
      route: '/inventory',
      icon: Icons.inventory_2_outlined,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Tạo mã vạch',
      route: '/barcode-gen',
      icon: Icons.qr_code_2,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Quét mã vạch',
      route: '/barcode-scan',
      icon: Icons.qr_code_scanner,
      allowedRoleIds: {AuthSession.staffRoleId},
    ),
    SidebarItem(
      label: 'Xuất hàng',
      route: '/export',
      icon: Icons.north,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),

    SidebarItem(
      label: 'Nhà cung cấp',
      route: '/suppliers',
      icon: Icons.groups_outlined,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Quản lý nhân sự',
      route: '/users',
      icon: Icons.people_outline,
      allowedRoleIds: {AuthSession.adminRoleId},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _SidebarLogo(),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<int?>(
                future: roleIdFuture,
                builder: (context, snapshot) {
                  final roleId = snapshot.data;
                  final visibleItems = items
                      .where(
                        (item) =>
                            item.allowedRoleIds == null ||
                            (roleId != null &&
                                item.allowedRoleIds!.contains(roleId)),
                      )
                      .toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: visibleItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return _SidebarTile(
                        item: item,
                        isActive: currentLocation == item.route,
                        onTap: () => onNavigate(item.route),
                      );
                    },
                  );
                },
              ),
            ),
            const _SidebarUser(),
          ],
        ),
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Smart Logistics',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? Colors.white : AppColors.textSecondary;

    return Material(
      color: isActive ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(item.icon, color: foreground, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarUser extends StatelessWidget {
  const _SidebarUser();

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('fullName') ?? 'Người dùng',
      'role': prefs.getString('roleName') ?? 'N/A',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'] ?? '...';
        final role = snapshot.data?['role'] ?? '...';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final authService = AuthService();
              await authService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
