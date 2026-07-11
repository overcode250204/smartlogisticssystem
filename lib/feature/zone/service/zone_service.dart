import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/zone_model.dart';
import 'package:dio/dio.dart';

class ZoneService {
  final ApiClient _client = ApiClient();

  Future<List<ZoneModel>> getAllZones() async {
    try {
      final response = await _client.get('zones');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => ZoneModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching zones: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<ZoneModel> getZoneById(int id) async {
    try {
      final response = await _client.get('zones/$id');
      if (response.statusCode == 200) {
        return ZoneModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin khu vực',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ZoneModel> createZone(ZoneCreateRequest request) async {
    try {
      final response = await _client.post('zones', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ZoneModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo khu vực',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error creating zone: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<ZoneModel?> updateZone(int id, ZoneCreateRequest request) async {
    try {
      final response = await _client.put('zones/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return ZoneModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        print('Error updating zone: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<bool> deleteZone(int id) async {
    try {
      final response = await _client.delete('zones/$id');
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
