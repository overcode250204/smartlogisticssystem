import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/barcode_scan_page.dart';
import 'package:smartlogisticssystem/feature/notification/services/notification_api_service.dart';
import 'package:smartlogisticssystem/feature/notification/services/notification_socket_service.dart';
import 'package:smartlogisticssystem/feature/notification/widgets/notification_center_panel.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final AuthService _authService = AuthService();
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final NotificationSocketService _notificationSocketService =
      NotificationSocketService();
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
      final count = await _notificationApiService.countUnread(userId);
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (error) {
      debugPrint('Unable to load staff notifications: $error');
    }

    _notificationSocketService.connect(
      recipientId: userId,
      onNotification: _handleRealtimeNotification,
    );
  }

  void _handleRealtimeNotification(NotificationModel notification) {
    if (!mounted) return;
    _notificationsNotifier.value = [
      notification,
      ..._notificationsNotifier.value.where(
        (item) => item.id != notification.id,
      ),
    ];
    setState(() {
      if (!notification.isRead) _notificationCount += 1;
    });
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
      final notifications = await _notificationApiService.getNotifications(
        userId,
      );
      _notificationsNotifier.value = notifications;
      if (mounted) {
        setState(() {
          _notificationCount = notifications
              .where((notification) => !notification.isRead)
              .length;
        });
      }
    } catch (error) {
      debugPrint('Unable to load staff notification list: $error');
    } finally {
      _notificationsLoadingNotifier.value = false;
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    await _notificationApiService.markAsRead(notification.id);
    _notificationsNotifier.value = _notificationsNotifier.value
        .map(
          (item) => item.id == notification.id
              ? item.copyWith(isRead: true, readAt: DateTime.now())
              : item,
        )
        .toList();

    if (mounted) {
      setState(() {
        if (_notificationCount > 0) _notificationCount -= 1;
      });
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!mounted || notification.type != 'PALLETIZATION_TASK') return;
    Navigator.of(context, rootNavigator: true).pop();
    final referenceId = notification.referenceId;
    if (referenceId != null) {
      context.go('/staff/pallet-tasks/$referenceId');
      return;
    }
    context.go('/staff/pallet-tasks');
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

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên kho'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Thông báo',
                onPressed: _openNotificationCenter,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _notificationCount > 99
                          ? '99+'
                          : _notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warehouse, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Màn hình chức năng Nhân viên kho',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/staff/pallet-tasks'),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Đóng gói pallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StaffExportScanPage(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét QR / Barcode lô hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
