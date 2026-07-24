import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';

class NotificationApiService {
  final ApiClient _client = ApiClient();

  Future<List<NotificationModel>> getNotifications(
    int recipientId, {
    bool? isRead,
  }) async {
    final response = await _client.get(
      'notifications',
      queryParameters: {
        'recipientId': recipientId,
        if (isRead != null) 'isRead': isRead,
      },
    );
    if (response.statusCode == 200 && response.data['data'] is List) {
      return (response.data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    }

    return [];
  }

  /// Chỉ lấy các thông báo chưa đọc (backend là nguồn dữ liệu chính).
  Future<List<NotificationModel>> getUnreadNotifications(int recipientId) {
    return getNotifications(recipientId, isRead: false);
  }

  Future<int> countUnread(int recipientId) async {
    final response = await _client.get(
      'notifications/unread-count',
      queryParameters: {'recipientId': recipientId},
    );
    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data is int) return data;
      if (data is num) return data.toInt();
      return int.tryParse(data?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _client.patch('notifications/$notificationId/read');
  }
}
