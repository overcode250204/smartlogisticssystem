import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/unit_response.dart';

class UnitService {
  UnitService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<UnitResponse>> getAll({UnitType? type}) async {
    try {
      final response = await _client.get(
        'units',
        queryParameters: {if (type != null) 'type': type.name},
      );

      final rawData = response.data is Map<String, dynamic>
          ? response.data['data']
          : response.data;

      if (response.statusCode != 200) {
        throw Exception('Không thể tải danh sách đơn vị');
      }

      if (rawData is! List) {
        throw Exception('Danh sách đơn vị trả về không hợp lệ');
      }

      return rawData
          .map(
            (item) =>
                UnitResponse.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;

      throw Exception(
        serverMessage ?? e.message ?? 'Không thể tải danh sách đơn vị',
      );
    }
  }

  Future<List<UnitResponse>> getByType(UnitType type) {
    return getAll(type: type);
  }
}
