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
      return response.statusCode == 200;
    } catch (e) {
      print('Lỗi tạo user: $e');
      return false;
    }
  }

  Future<bool> updateUser(
    int userId,
    String fullName,
    String phone,
    int roleId,
    bool isActive,
  ) async {
    try {
      final response = await _client.put(
        '/users/$userId',
        data: {
          'fullName': fullName,
          'phone': phone,
          'roleId': roleId,
          'isActive': isActive,
        },
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

  // Tìm kiếm với 3 điều kiện (Các tham số được bọc trong {} để có thể truyền hoặc không truyền)
  Future<List<UserModel>> searchUsers({
    String? keyword,
    int? roleId,
    bool? isActive,
  }) async {
    try {
      // Chỉ đưa vào queryParameters những biến có dữ liệu
      Map<String, dynamic> queryParams = {};
      if (keyword != null && keyword.trim().isNotEmpty)
        queryParams['keyword'] = keyword.trim();
      if (roleId != null) queryParams['roleId'] = roleId;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _client.get(
        '/users/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi tìm kiếm users: $e');
      return [];
    }
  }
}
