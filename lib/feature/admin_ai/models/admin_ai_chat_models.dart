class AdminAiChatRequest {
  final String question;
  final String timeFilter;

  const AdminAiChatRequest({required this.question, required this.timeFilter});

  Map<String, dynamic> toJson() {
    return {'question': question, 'timeFilter': timeFilter};
  }
}

class AdminAiChatResponse {
  final String answer;
  final String severity;
  final List<String> insights;
  final List<String> recommendedActions;
  final List<String> usedData;
  final double confidence;
  final bool fallback;

  const AdminAiChatResponse({
    required this.answer,
    required this.severity,
    required this.insights,
    required this.recommendedActions,
    required this.usedData,
    required this.confidence,
    required this.fallback,
  });

  factory AdminAiChatResponse.fromJson(Map<String, dynamic> json) {
    return AdminAiChatResponse(
      answer: json['answer']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'LOW',
      insights: _stringList(json['insights']),
      recommendedActions: _stringList(json['recommendedActions']),
      usedData: _stringList(json['usedData']),
      confidence: _doubleValue(json['confidence']),
      fallback: json['fallback'] == true,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class AdminAiConversationMessage {
  final String content;
  final DateTime createdAt;
  final bool fromUser;
  final AdminAiChatResponse? response;

  const AdminAiConversationMessage({
    required this.content,
    required this.createdAt,
    required this.fromUser,
    this.response,
  });
}
