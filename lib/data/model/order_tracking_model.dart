class OrderTrackingModel {
  final int trackingId;
  final int orderId;
  final double latitude;
  final double longitude;
  final String recordedAt;
  final String? note;

  const OrderTrackingModel({
    required this.trackingId,
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.note,
  });

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) {
    return OrderTrackingModel(
      trackingId: (json['trackingId'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}
