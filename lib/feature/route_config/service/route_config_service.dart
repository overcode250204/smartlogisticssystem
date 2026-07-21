import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:dio/dio.dart';

class RouteConfigService {
  final ApiClient _client = ApiClient();

  Future<List<RouteConfigModel>> getAllRouteConfigs() async {
    try {
      final response = await _client.get('route-configs');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => RouteConfigModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching route configs: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<RouteConfigModel> getRouteConfigById(int id) async {
    try {
      final response = await _client.get('route-configs/$id');
      if (response.statusCode == 200) {
        return RouteConfigModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy cấu hình tuyến đường',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<RouteConfigModel> createRouteConfig(RouteConfigCreateRequest request) async {
    try {
      final response = await _client.post('route-configs', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return RouteConfigModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo cấu hình tuyến đường',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error creating route config: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<RouteConfigModel?> updateRouteConfig(int id, RouteConfigUpdateRequest request) async {
    try {
      final response = await _client.put('route-configs/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return RouteConfigModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('Error updating route config: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<bool> deleteRouteConfig(int id) async {
    try {
      final response = await _client.delete('route-configs/$id');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
