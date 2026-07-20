class ExceptionReasonModel {
  final int reasonId;
  final String category;
  final String reasonText;
  final bool isActive;

  const ExceptionReasonModel({
    required this.reasonId,
    required this.category,
    required this.reasonText,
    required this.isActive,
  });

  factory ExceptionReasonModel.fromJson(Map<String, dynamic> json) {
    return ExceptionReasonModel(
      reasonId: json['reasonId'] as int? ?? 0,
      category: json['category']?.toString() ?? '',
      reasonText: json['reasonText']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reasonId': reasonId,
      'category': category,
      'reasonText': reasonText,
      'isActive': isActive,
    };
  }
}

class ExceptionReasonCreateRequest {
  final String category;
  final String reasonText;
  final bool isActive;

  const ExceptionReasonCreateRequest({
    required this.category,
    required this.reasonText,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'reasonText': reasonText,
      'isActive': isActive,
    };
  }
}

class ExceptionReasonUpdateRequest {
  final String category;
  final String reasonText;
  final bool isActive;

  const ExceptionReasonUpdateRequest({
    required this.category,
    required this.reasonText,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'reasonText': reasonText,
      'isActive': isActive,
    };
  }
}
