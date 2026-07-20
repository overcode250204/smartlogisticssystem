class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? recipientId;
  final String? referenceType;
  final int? referenceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.recipientId,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Thông báo mới',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      recipientId: _parseInt(json['recipientId']),
      referenceType: json['referenceType']?.toString(),
      referenceId: _parseInt(json['referenceId']),
      isRead: _parseBool(json['isRead'] ?? json['read']) ?? false,
      readAt: _parseDateTime(json['readAt']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      recipientId: recipientId,
      referenceType: referenceType,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
