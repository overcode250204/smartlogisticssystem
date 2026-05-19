import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, int>?> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      print('Phản hồi từ Server: ${response.data}');

      if (response.statusCode == 200) {
        final userData = response.data['data'];

        return {
          'roleId': userData['roleId'] as int,
          'userId': userData['userId'] as int,
        };
      }

      return null;
    } catch (e) {
      print('Fail to Login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error logout $e');
    }
  }

  Future<bool> registerDriver(
    String fullName,
    String idCard,
    String phone,
    String password,
  ) async {
    try {
      final response = await _client.post(
        '/auth/register-driver', // Đường dẫn API Spring Boot vừa tạo ở trên
        data: {
          'fullName': fullName,
          'phone': phone,
          'idCard': idCard, // Nếu DB bạn có lưu CCCD
          'password': password,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi Đăng ký: $e');
      return false;
    }
  }
}
