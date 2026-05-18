// File: lib/features/auth_nguyen/user_service.dart
import '../../../core/networking.dart';
import '../../../data/model/user_model.dart';

class UserService {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client.get('/users');

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'];
        print(dataList);
        return dataList.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi khi lấy danh sách user: $e');
      return [];
    }
  }

  // 2. THÊM MỚI
  Future<bool> createUser(
    String fullName,
    String email,
    String phone,
    String password,
    int roleId,
  ) async {
    try {
      final response = await _client.post(
        '/users',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'roleId': roleId,
          'isActive': true,
        },
      );
      // HTTP 200 hoặc 201 đều là tạo thành công
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi tạo user: $e');
      return false;
    }
  }

  // 3. SỬA (CẬP NHẬT)
  Future<bool> updateUser(
    int userId,
    String fullName,
    String phone,
    int roleId,
  ) async {
    try {
      final response = await _client.put(
        '/users/$userId',
        data: {'fullName': fullName, 'phone': phone, 'roleId': roleId},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi cập nhật user: $e');
      return false;
    }
  }

  // 4. XÓA (MỀM)
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _client.delete('/users/$userId');
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi xóa user: $e');
      return false;
    }
  }
}
