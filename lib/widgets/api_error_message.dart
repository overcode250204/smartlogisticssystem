import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (error.response == null) {
      return 'Không thể kết nối backend';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Lỗi quyền truy cập';
    }
    if (statusCode == 500) {
      return 'Lỗi máy chủ, vui lòng thử lại';
    }
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (statusCode == 400 || statusCode == 404) {
      return 'Yêu cầu không hợp lệ hoặc không có dữ liệu';
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
  }

  return error.toString();
}
