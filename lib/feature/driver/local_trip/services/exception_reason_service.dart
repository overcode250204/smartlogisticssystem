import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/exception_reason_response_model.dart';

class ExceptionReasonService {
  final ApiClient _client = ApiClient();

  /// GET /api/admin/exception-reasons — no auth header required.
  /// Only active reasons should be shown in the fail-reason dropdown.
  Future<List<ExceptionReasonResponse>> getActiveReasons() async {
    final response = await _client.get('admin/exception-reasons');
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : body;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ExceptionReasonResponse.fromJson)
        .where((reason) => reason.isActive)
        .toList();
  }
}
