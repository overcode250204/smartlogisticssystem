import 'package:dio/dio.dart';

/// Local Trip business-rule errors always come back as a JSON body with a
/// `message` field, regardless of HTTP status code (most are HTTP 500 —
/// see docs/local-trip-frontend-guide.md §2). This parses that message
/// out and strips the generic wrapper prefix, instead of treating the
/// status code as a fatal/system error.
String localTripErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) {
        const prefix = 'An unexpected error occurred: ';
        return message.startsWith(prefix)
            ? message.substring(prefix.length)
            : message;
      }
    }
    if (error.response == null) {
      return 'Không thể kết nối máy chủ';
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
  }
  return error.toString();
}
