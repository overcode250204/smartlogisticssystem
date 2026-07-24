import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/notification/services/notification_api_service.dart';
import 'package:smartlogisticssystem/feature/notification/services/notification_socket_service.dart';
import 'package:smartlogisticssystem/feature/notification/widgets/notification_center_panel.dart';
import 'package:smartlogisticssystem/widgets/sidebar.dart';
import 'package:smartlogisticssystem/widgets/topbar.dart';

class AppShell extends StatefulWidget {
  final String location;
  final String title;
  final Widget child;

  const AppShell({
    super.key,
    required this.location,
    required this.title,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final NotificationSocketService _notificationSocketService =
      NotificationSocketService();
  final AuthService _authService = AuthService();
  final ValueNotifier<List<NotificationModel>> _notificationsNotifier =
      ValueNotifier<List<NotificationModel>>([]);
  final ValueNotifier<bool> _notificationsLoadingNotifier = ValueNotifier<bool>(
    false,
  );

  int _notificationCount = 0;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  @override
  void dispose() {
    _notificationSocketService.disconnect();
    _notificationsNotifier.dispose();
    _notificationsLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _setupNotifications() async {
    final userId = await AuthSession.getUserId();
    if (!mounted || userId == null) return;
    _userId = userId;

    try {
      final unreadCount = await _notificationApiService.countUnread(userId);
      if (mounted) {
        setState(() {
          _notificationCount = unreadCount;
        });
      }
    } catch (error) {
      debugPrint('Unable to load unread notification count: $error');
    }

    if (!mounted) return;

    _notificationSocketService.connect(
      recipientId: userId,
      onNotification: _handleRealtimeNotification,
    );
  }

  void _handleRealtimeNotification(NotificationModel notification) {
    if (!mounted) return;

    // Danh sách chỉ chứa thông báo chưa đọc -> bỏ qua nếu đã đọc.
    if (!notification.isRead) {
      _notificationsNotifier.value = [
        notification,
        ..._notificationsNotifier.value.where(
          (item) => item.id != notification.id,
        ),
      ];

      setState(() {
        _notificationCount += 1;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.message}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _loadNotifications() async {
    final userId = _userId ?? await AuthSession.getUserId();
    if (userId == null) return;
    _userId = userId;

    _notificationsLoadingNotifier.value = true;
    try {
      // Chỉ lấy thông báo chưa đọc từ backend (nguồn dữ liệu chính).
      final notifications = await _notificationApiService.getUnreadNotifications(
        userId,
      );
      _notificationsNotifier.value = notifications;
      if (mounted) {
        setState(() {
          _notificationCount = notifications.length;
        });
      }
    } catch (error) {
      debugPrint('Unable to load notifications: $error');
    } finally {
      _notificationsLoadingNotifier.value = false;
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    try {
      await _notificationApiService.markAsRead(notification.id);
    } catch (error) {
      debugPrint('Unable to mark notification as read: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đánh dấu đã đọc. Vui lòng thử lại.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      // Ném lại để dừng luồng: không điều hướng, không cập nhật trạng thái giả.
      rethrow;
    }

    // Thành công -> refetch để danh sách chưa đọc và badge phản ánh đúng backend.
    await _loadNotifications();
  }

  void _openNotificationCenter() {
    _loadNotifications();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      builder: (context) => NotificationCenterPanel(
        notifications: _notificationsNotifier,
        isLoading: _notificationsLoadingNotifier,
        onRefresh: _loadNotifications,
        onMarkAsRead: _markNotificationAsRead,
        onNotificationTap: _handleNotificationTap,
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!mounted) return;
    if (notification.type != 'PALLETIZATION_TASK') return;

    Navigator.of(context, rootNavigator: true).pop();
    final referenceId = notification.referenceId;
    if (referenceId != null) {
      context.go('/staff/pallet-tasks/$referenceId');
      return;
    }
    context.go('/staff/pallet-tasks');
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: Row(
        children: [
          Sidebar(
            currentLocation: widget.location,
            roleIdFuture: AuthSession.getRoleId(),
            onNavigate: (route) {
              if (route != widget.location) context.go(route);
            },
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: widget.title,
                  notificationCount: _notificationCount,
                  onNotificationPressed: _openNotificationCenter,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
