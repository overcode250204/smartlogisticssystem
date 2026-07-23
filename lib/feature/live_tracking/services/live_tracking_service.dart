import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ActiveVehicleInfo {
  final String tripCode;
  final String shipperName;
  final String deadline;
  final double? lat;
  final double? lng;
  final String status;
  final String? lastPingTime;

  ActiveVehicleInfo({
    required this.tripCode,
    required this.shipperName,
    required this.deadline,
    this.lat,
    this.lng,
    required this.status,
    this.lastPingTime,
  });

  factory ActiveVehicleInfo.fromJson(Map<String, dynamic> json) {
    return ActiveVehicleInfo(
      tripCode: json['trip_code'] ?? '',
      shipperName: json['shipper_name'] ?? '',
      deadline: json['deadline'] ?? '',
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      status: json['status'] ?? 'gray',
      lastPingTime: json['last_ping_time'],
    );
  }
}

class LiveTrackingService {
  StompClient? _client;
  Timer? _pingTimer;
  StreamSubscription? _locationSubscription;
  bool get isConnected => _client?.connected ?? false;

  // For Admin: subscribe to real-time updates of all active vehicles
  void connectAdminRoom({
    required Function(ActiveVehicleInfo) onUpdate,
  }) {
    if (isConnected) return;

    final socketUrl = ApiClient.getWebSocketUrl();
    _client = StompClient(
      config: StompConfig(
        url: socketUrl,
        onConnect: (frame) {
          debugPrint('LiveTracking socket connected: $socketUrl');
          _client?.subscribe(
            destination: '/topic/admin_room',
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.trim().isEmpty) return;

              final decoded = jsonDecode(body);
              if (decoded is! Map<String, dynamic>) return;

              final info = ActiveVehicleInfo.fromJson(decoded);
              onUpdate(info);
            },
          );
        },
        onWebSocketError: (error) {
          debugPrint('LiveTracking socket error: $error');
        },
        onStompError: (frame) {
          debugPrint('LiveTracking STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('LiveTracking socket disconnected');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  // For Driver: start sending location ping periodically
  void startDriverTracking({
    required String tripCode,
    required Stream<Map<String, double>> locationStream,
    Duration pingInterval = const Duration(seconds: 30),
  }) {
    if (isConnected) disconnect();

    final socketUrl = ApiClient.getWebSocketUrl();
    _client = StompClient(
      config: StompConfig(
        url: socketUrl,
        onConnect: (frame) {
          debugPrint('Driver LiveTracking socket connected: $socketUrl');
          
          double currentLat = 10.762;
          double currentLng = 106.660;

          // Listen to the real location stream if available
          _locationSubscription = locationStream.listen((coords) {
            currentLat = coords['lat'] ?? currentLat;
            currentLng = coords['lng'] ?? currentLng;

            // Immediately send coordinate to server for fast updates in simulation
            if (pingInterval.inSeconds < 10 && isConnected) {
              final payload = {
                'trip_code': tripCode,
                'lat': currentLat,
                'lng': currentLng,
              };
              _client?.send(
                destination: '/app/track-location',
                body: jsonEncode(payload),
              );
            }
          });

          // Periodically push location updates to BE
          _pingTimer = Timer.periodic(pingInterval, (timer) {
            if (isConnected) {
              final payload = {
                'trip_code': tripCode,
                'lat': currentLat,
                'lng': currentLng,
              };
              debugPrint('Sending driver tracking payload: $payload');
              _client?.send(
                destination: '/app/track-location',
                body: jsonEncode(payload),
              );
            }
          });
        },
        onWebSocketError: (error) {
          debugPrint('Driver LiveTracking socket error: $error');
        },
        onStompError: (frame) {
          debugPrint('Driver LiveTracking STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('Driver LiveTracking socket disconnected');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  // Fetch all active vehicles initially via REST API
  Future<List<ActiveVehicleInfo>> fetchActiveVehicles() async {
    final client = ApiClient();
    try {
      final response = await client.get('live-tracking/active-vehicles');
      if (response.data != null && response.data['data'] != null) {
        final list = response.data['data'] as List;
        return list.map((item) => ActiveVehicleInfo.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch active vehicles: $e');
    }
    return [];
  }

  void disconnect() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _client?.deactivate();
    _client = null;
  }
}
