import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_model.dart';

class InventoryBatchService {
  final ApiClient _client = ApiClient();

  Future<List<InventoryBatchModel>> getAllBatches() async {
    try {
      final response = await _client.get('inventory-batches');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => InventoryBatchModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getAllBatches: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<InventoryBatchModel> exportStock({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _client.post(
        'inventory-batches/export',
        data: {'productId': productId, 'quantity': quantity},
      );
      if (response.statusCode == 200) {
        return InventoryBatchModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể xuất kho lô hàng',
      );
    } catch (e) {
      print('Error in exportStock: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<InventoryBatchModel> createBatch(InventoryBatchModel batch) async {
    try {
      final response = await _client.post(
        'inventory-batches',
        data: batch.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InventoryBatchModel.fromJson(response.data['data']);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo lô hàng',
      );
    } catch (e) {
      print('Error in createBatch: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
