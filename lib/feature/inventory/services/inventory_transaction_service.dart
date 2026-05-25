import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';

class InventoryTransactionService {
  final ApiClient _client = ApiClient();

  Future<List<InventoryTransactionResponse>> getAllTransactions() async {
    try {
      final response = await _client.get('inventory-transactions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((item) => InventoryTransactionResponse.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error in getAllTransactions: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
