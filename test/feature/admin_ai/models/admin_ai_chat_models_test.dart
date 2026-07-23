import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/feature/admin_ai/models/admin_ai_chat_models.dart';

void main() {
  group('AdminAiChatResponse', () {
    test('parses response payload safely', () {
      final response = AdminAiChatResponse.fromJson({
        'answer': 'Vận hành ổn định.',
        'severity': 'HIGH',
        'insights': ['Có 2 cảnh báo'],
        'recommendedActions': ['Kiểm tra đơn FAILED'],
        'usedData': ['recentExceptions'],
        'confidence': '0.75',
        'fallback': true,
      });

      expect(response.answer, 'Vận hành ổn định.');
      expect(response.severity, 'HIGH');
      expect(response.insights, ['Có 2 cảnh báo']);
      expect(response.recommendedActions, ['Kiểm tra đơn FAILED']);
      expect(response.usedData, ['recentExceptions']);
      expect(response.confidence, 0.75);
      expect(response.fallback, isTrue);
    });

    test('uses defaults when optional fields are missing', () {
      final response = AdminAiChatResponse.fromJson({'answer': null});

      expect(response.answer, '');
      expect(response.severity, 'LOW');
      expect(response.insights, isEmpty);
      expect(response.recommendedActions, isEmpty);
      expect(response.usedData, isEmpty);
      expect(response.confidence, 0.0);
      expect(response.fallback, isFalse);
    });
  });

  group('AdminAiChatRequest', () {
    test('serializes question and time filter', () {
      const request = AdminAiChatRequest(
        question: 'Có cảnh báo nào không?',
        timeFilter: 'TODAY',
      );

      expect(request.toJson(), {
        'question': 'Có cảnh báo nào không?',
        'timeFilter': 'TODAY',
      });
    });
  });
}
