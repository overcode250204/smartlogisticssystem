import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:dio/dio.dart';

class WarehouseService {
  final ApiClient _client = ApiClient();

  Future<List<WarehouseModel>> getAllWarehouses() async {
    try {
      final response = await _client.get('warehouses');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => WarehouseModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching warehouses: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<WarehouseModel> getWarehouseById(int id) async {
    try {
      final response = await _client.get('warehouses/$id');
      if (response.statusCode == 200) {
        return WarehouseModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin nhà kho',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<WarehouseModel> createWarehouse(WarehouseCreateRequest request) async {
    try {
      final response = await _client.post('warehouses', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WarehouseModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo nhà kho',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error creating warehouse: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<WarehouseModel?> updateWarehouse(int id, WarehouseUpdateRequest request) async {
    try {
      final response = await _client.put('warehouses/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return WarehouseModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('Error updating warehouse: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<bool> deleteWarehouse(int id) async {
    try {
      final response = await _client.delete('warehouses/$id');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
