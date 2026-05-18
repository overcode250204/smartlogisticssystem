import 'package:smartlogisticssystem/core/networking.dart';

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
}
