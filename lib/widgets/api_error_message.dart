import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (error.response == null) {
      return 'Không thể kết nối backend. Vui lòng kiểm tra mạng hoặc thử lại sau.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Phiên đăng nhập không hợp lệ hoặc bạn không có quyền thực hiện thao tác này.';
    }
    if (statusCode == 500) {
      return 'Lỗi máy chủ, vui lòng thử lại sau.';
    }

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final messages = errors.values
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .map((value) => value.toString())
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }

      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return _friendlyServerMessage(message.toString());
      }

      final errorMessage = data['error'];
      if (errorMessage != null && errorMessage.toString().trim().isNotEmpty) {
        return _friendlyServerMessage(errorMessage.toString());
      }
    }

    if (statusCode == 400 || statusCode == 404) {
      return 'Thông tin gửi lên chưa hợp lệ. Vui lòng kiểm tra lại dữ liệu.';
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return _friendlyServerMessage(error.message!);
    }
  }

  final fallback = error.toString();
  if (fallback.startsWith('Exception: ')) {
    return fallback.replaceFirst('Exception: ', '');
  }
  return fallback;
}

String _friendlyServerMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('cannot deserialize') && lower.contains('paymenttype')) {
    return 'Phương thức thanh toán không hợp lệ. Vui lòng chọn COD hoặc thẻ tín dụng.';
  }
  if (lower.contains('not one of the values accepted') &&
      lower.contains('cod')) {
    return 'Phương thức thanh toán không hợp lệ. Vui lòng chọn COD hoặc thẻ tín dụng.';
  }
  if (lower.contains('httpmessagenotreadableexception')) {
    return 'Thông tin gửi lên chưa đúng định dạng. Vui lòng kiểm tra lại đơn hàng.';
  }
  if (lower.contains('dioexception')) {
    return 'Không thể hoàn tất yêu cầu. Vui lòng thử lại.';
  }
  return message;
}
