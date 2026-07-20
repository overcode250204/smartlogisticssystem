import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:dio/dio.dart';

class VehicleService {
  final ApiClient _client = ApiClient();

  Future<List<VehicleModel>> getAllVehicles({int? currentVehicleId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (currentVehicleId != null) {
        queryParams['currentVehicleId'] = currentVehicleId;
      }
      final response = await _client.get('vehicles', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => VehicleModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching vehicles: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<VehicleModel> getVehicleById(int id) async {
    try {
      final response = await _client.get('vehicles/$id');
      if (response.statusCode == 200) {
        return VehicleModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin phương tiện',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<VehicleModel> createVehicle(VehicleCreateRequest request) async {
    try {
      final response = await _client.post('vehicles', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return VehicleModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo phương tiện',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error creating vehicle: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<VehicleModel?> updateVehicle(int id, VehicleUpdateRequest request) async {
    try {
      final response = await _client.put('vehicles/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return VehicleModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('Error updating vehicle: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      final response = await _client.delete('vehicles/$id');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
