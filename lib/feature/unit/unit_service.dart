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

      final rawData = response.data['data'];

      if (response.statusCode != 200 || rawData is! List) {
        throw Exception('Không thể tải danh sách đơn vị');
      }

      return rawData
          .map(
            (item) =>
                UnitResponse.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message']?.toString() ??
            'Không thể kết nối đến API units',
      );
    }
  }

  Future<List<UnitResponse>> getByType(UnitType type) {
    return getAll(type: type);
  }
}
