import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/feature/admin_ai/models/admin_ai_chat_models.dart';

class AdminAiAssistantService {
  final ApiClient _client;

  AdminAiAssistantService({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<AdminAiChatResponse> chat({
    required String question,
    required String timeFilter,
  }) async {
    final request = AdminAiChatRequest(
      question: question,
      timeFilter: timeFilter,
    );

    final response = await _client.post(
      'admin/ai-assistant/chat',
      data: request.toJson(),
      options: Options(
        receiveTimeout: const Duration(seconds: 75),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return AdminAiChatResponse.fromJson(data);
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Không thể nhận phản hồi từ trợ lý vận hành.',
    );
  }
}
