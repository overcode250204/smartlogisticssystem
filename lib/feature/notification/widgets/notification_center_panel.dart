import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';

class NotificationCenterPanel extends StatelessWidget {
  final ValueNotifier<List<NotificationModel>> notifications;
  final ValueNotifier<bool> isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(NotificationModel notification) onMarkAsRead;
  final Future<void> Function(NotificationModel notification)?
  onNotificationTap;

  const NotificationCenterPanel({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onMarkAsRead,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.only(top: 72, right: 24, left: 24),
      alignment: Alignment.topRight,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 390,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PanelHeader(onRefresh: onRefresh),
              const Divider(height: 1, color: AppColors.border),
              ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  if (loading) {
                    return const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  return ValueListenableBuilder<List<NotificationModel>>(
                    valueListenable: notifications,
                    builder: (context, items, _) {
                      if (items.isEmpty) {
                        return const SizedBox(
                          height: 220,
                          child: Center(
                            child: Text(
                              'Chưa có thông báo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }

                      return Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final notification = items[index];
                            return _NotificationTile(
                              notification: notification,
                              onTap: () async {
                                await onMarkAsRead(notification);
                                await onNotificationTap?.call(notification);
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _PanelHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Thông báo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final Future<void> Function() onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final createdAtText = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(notification.createdAt);
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? AppColors.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: unread ? AppColors.danger : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    createdAtText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
