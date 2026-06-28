import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_status.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_batch_service.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_transaction_service.dart';

class InventoryService {
  final ProductService _productService = ProductService();
  final InventoryBatchService _batchService = InventoryBatchService();
  final InventoryTransactionService _transactionService =
      InventoryTransactionService();

  Future<InventoryDashboardData> fetchDashboardData() async {
    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _batchService.getAllBatches(),
        _transactionService.getAllTransactions(),
      ]);

      final products = results[0] as List<ProductResponse>;
      final batches = _attachProducts(
        results[1] as List<InventoryBatchResponse>,
        products,
      );

      return InventoryDashboardData(
        products: products,
        batches: batches,
        transactions: results[2] as List<InventoryTransactionResponse>,
      );
    } catch (e) {
      print('Error in fetchDashboardData: $e');
      if (e is DioException) {
        print('Response Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  List<InventoryBatchResponse> _attachProducts(
    List<InventoryBatchResponse> batches,
    List<ProductResponse> products,
  ) {
    return batches.map((batch) {
      if (batch.product != null) return batch;
      // Because batch.productId does not exist in InventoryBatchResponse, we rely on API to return product.
      // If we need client-side attachment, we would need productId in response.
      // But for now let's just return batch as is.
      return batch;
    }).toList();
  }
}

class InventoryDashboardData {
  final List<ProductResponse> products;
  final List<InventoryBatchResponse> batches;
  final List<InventoryTransactionResponse> transactions;

  const InventoryDashboardData({
    required this.products,
    required this.batches,
    required this.transactions,
  });

  int get lowStockCount => batches
      .where(
        (batch) {
          if (batch.status == InventoryBatchStatus.LOW_STOCK) {
            return true;
          }

          final productId = batch.product?.productId;
          if (productId == null) {
            return false;
          }

          final matchingProducts = products.where((p) => p.productId == productId);
          if (matchingProducts.isEmpty) {
            return false;
          }

          final minStockLevel = matchingProducts.first.minStockLevel ?? 0;
          return batch.remainingQuantity <= minStockLevel;
        },
      )
      .length;
}
