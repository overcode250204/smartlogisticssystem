import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_transaction_service.dart';

class ExportService {
  final ApiClient _client = ApiClient();
  final InventoryTransactionService _transactionService =
      InventoryTransactionService();
  final DateFormat _apiDateFormatter = DateFormat('yyyy-MM-dd');

  Future<List<InventoryTransactionResponse>> getExportHistory() async {
    final transactions = await _transactionService.getAllTransactions();
    final exports =
        transactions
            .where((item) => item.type.toUpperCase() == 'EXPORT')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return exports;
  }

  Future<InventoryBatchBarcodeResponse> exportBatch({
    required int batchId,
    required int quantity,
    required DateTime exportDate,
  }) async {
    final response = await _client.patch(
      'inventory-batches/$batchId/deduct',
      data: {
        'quantity': quantity,
        // The current backend records createdAt automatically; keep the
        // formatted date here for the UI-facing contract.
        'exportDate': _apiDateFormatter.format(exportDate),
      },
    );

    if (response.statusCode == 200 && response.data['data'] != null) {
      return InventoryBatchBarcodeResponse.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Khong the xuat hang',
    );
  }
}
