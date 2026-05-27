import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_request_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';

class InventoryBatchService {
  final ApiClient _client = ApiClient();

  Future<List<InventoryBatchResponse>> getAllBatches() async {
    try {
      final response = await _client.get('inventory-batches');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((item) => InventoryBatchResponse.fromJson(item))
            .toList();
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

  Future<InventoryExportResponse> exportStock({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _client.post(
        'inventory-batches/export',
        data: {'productId': productId, 'quantity': quantity},
      );
      if (response.statusCode == 200) {
        return InventoryExportResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể xuất kho',
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

  Future<InventoryBatchResponse> createBatch(
    InventoryBatchCreateRequest request,
  ) async {
    try {
      final response = await _client.post(
        'inventory-batches',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InventoryBatchResponse.fromJson(response.data['data']);
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
