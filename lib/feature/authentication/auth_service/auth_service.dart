import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, int>?> login(String email, String password) async {
    try {
      final response = await _client.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );

      print('Phản hồi từ Server: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final userData = responseData['data'] as Map<String, dynamic>?;

        if (userData == null) return null;

        return {
          'roleId': _parseInt(userData['roleId']),
          'userId': _parseInt(userData['userId']),
        };
      }

      return null;
    } catch (e) {
      print('Fail to Login: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
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

  Future<bool> registerDriver(UserModel userDTO) async {
    try {
      print(userDTO.toString());
      final response = await _client.post(
        'auth/register-driver',
        data: userDTO.toJson(),
      );
      print(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      return false;
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
