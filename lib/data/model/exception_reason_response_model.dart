class ExceptionReasonResponse {
  final int reasonId;
  final String category;
  final String reasonText;
  final bool isActive;

  const ExceptionReasonResponse({
    required this.reasonId,
    required this.category,
    required this.reasonText,
    required this.isActive,
  });

  factory ExceptionReasonResponse.fromJson(Map<String, dynamic> json) {
    return ExceptionReasonResponse(
      reasonId: _parseInt(json['reasonId']) ?? 0,
      category: json['category']?.toString() ?? '',
      reasonText: json['reasonText']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
