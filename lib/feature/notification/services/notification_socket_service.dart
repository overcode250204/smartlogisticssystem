import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef NotificationReceived = void Function(NotificationModel notification);

class NotificationSocketService {
  StompClient? _client;
  int? _recipientId;

  bool get isConnected => _client?.connected ?? false;

  void connect({
    required int recipientId,
    required NotificationReceived onNotification,
  }) {
    if (_recipientId == recipientId && isConnected) return;

    disconnect();
    _recipientId = recipientId;

    final socketUrl = ApiClient.getWebSocketUrl();
    _client = StompClient(
      config: StompConfig(
        url: socketUrl,
        onConnect: (frame) {
          final topic = '/topic/notifications/$recipientId';
          debugPrint('Notification socket connected: $socketUrl');
          debugPrint('Subscribing notification topic: $topic');

          _client?.subscribe(
            destination: topic,
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.trim().isEmpty) return;

              final decoded = jsonDecode(body);
              if (decoded is! Map<String, dynamic>) return;

              final notification = NotificationModel.fromJson(decoded);
              debugPrint(
                'Realtime notification received: '
                '${notification.title} - ${notification.message}',
              );
              onNotification(notification);
            },
          );
        },
        onWebSocketError: (error) {
          debugPrint('Notification socket error: $error');
        },
        onStompError: (frame) {
          debugPrint('Notification STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('Notification socket disconnected');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _recipientId = null;
  }
}
