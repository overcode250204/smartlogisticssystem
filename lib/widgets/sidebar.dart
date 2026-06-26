import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';

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
  final Future<void> Function()? onLogout;

  const Sidebar({
    super.key,
    required this.currentLocation,
    required this.roleIdFuture,
    required this.onNavigate,
    this.onLogout,
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
      label: 'Tạo sản phẩm',
      route: '/product',
      icon: Icons.qr_code_2,
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
      allowedRoleIds: {AuthSession.adminRoleId, AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Nhà cung cấp',
      route: '/suppliers',
      icon: Icons.groups_outlined,
      allowedRoleIds: {AuthSession.managerRoleId},
    ),
    SidebarItem(
      label: 'Danh mục',
      route: '/categories',
      icon: Icons.category_outlined,
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
            _SidebarUser(onLogout: onLogout),
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
  final Future<void> Function()? onLogout;

  const _SidebarUser({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionUser?>(
      future: AuthSession.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'Người dùng';
        final displayRole = user?.displayRole ?? 'Người dùng';

        return Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: InkWell(
            onTap: user == null ? null : () => _showUserMenu(context, user),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayRole,
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
                    Icons.keyboard_arrow_down_rounded,
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

  Future<void> _showUserMenu(BuildContext context, SessionUser user) async {
    final selection = await showMenu<_UserMenuAction>(
      context: context,
      position: _menuPosition(context),
      items: const [
        PopupMenuItem(
          value: _UserMenuAction.accountInfo,
          child: Text('Thông tin tài khoản'),
        ),
        PopupMenuItem(value: _UserMenuAction.logout, child: Text('Đăng xuất')),
      ],
    );

    if (!context.mounted || selection == null) return;

    switch (selection) {
      case _UserMenuAction.accountInfo:
        _showAccountDialog(context, user);
        break;
      case _UserMenuAction.logout:
        await _confirmLogout(context);
        break;
    }
  }

  RelativeRect _menuPosition(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    return RelativeRect.fromLTRB(
      offset.dx + 16,
      offset.dy,
      offset.dx + box.size.width,
      offset.dy + box.size.height,
    );
  }

  void _showAccountDialog(BuildContext context, SessionUser user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccountInfoRow(label: 'Họ tên', value: user.displayName),
            const SizedBox(height: 10),
            _AccountInfoRow(
              label: 'Email',
              value: user.email.isNotEmpty ? user.email : 'Chưa có email',
            ),
            const SizedBox(height: 10),
            _AccountInfoRow(label: 'Vai trò', value: user.displayRole),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && onLogout != null) {
      await onLogout!();
    }
  }
}

enum _UserMenuAction { accountInfo, logout }

class _AccountInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AccountInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
