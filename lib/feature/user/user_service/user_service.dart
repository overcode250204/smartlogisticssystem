// File: lib/features/auth_nguyen/user_service.dart
import '../../../core/networking.dart';
import '../../../data/model/user_model.dart';

class UserService {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client.get('users');

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
    String? identificationNumber,
    String? origin,
    String? address, {
    String? driverType,
    int? zoneId,
    int? currentWarehouseId,
    int? currentVehicleId,
  }) async {
    try {
      final response = await _client.post(
        'users',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'roleId': roleId,
          'isActive': true,
          'identificationNumber': identificationNumber,
          'origin': origin,
          'address': address,
          'driverType': driverType,
          'zoneId': zoneId,
          'currentWarehouseId': currentWarehouseId,
          'currentVehicleId': currentVehicleId,
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
    String? identificationNumber,
    String? origin,
    String? address, {
    String? driverType,
    int? zoneId,
    int? currentWarehouseId,
    int? currentVehicleId,
  }) async {
    try {
      final response = await _client.put(
        'users/$userId',
        data: {
          'fullName': fullName,
          'phone': phone,
          'roleId': roleId,
          'isActive': isActive,
          'identificationNumber': identificationNumber,
          'origin': origin,
          'address': address,
          'driverType': driverType,
          'zoneId': zoneId,
          'currentWarehouseId': currentWarehouseId,
          'currentVehicleId': currentVehicleId,
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
      final response = await _client.delete('users/$userId');
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
        'users/search',
        queryParameters: queryParams,
      );

      print('🔍 Search Response Content: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data['data'];
        if (rawData is List) {
          return rawData.map((json) => UserModel.fromJson(json)).toList();
        } else {
          print('⚠️ Warning: Expected data is not a List, got: ${rawData.runtimeType}');
        }
      }
      return [];
    } catch (e, stack) {
      print('❌ Error searching users: $e');
      print('Stacktrace: $stack');
      return [];
    }
  }
}
