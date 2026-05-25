import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
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

  InventoryDashboardData mockDashboardData() {
    final supplierA = SupplierSimpleResponse(
      supplierId: 1,
      supplierName: 'Công ty TNHH ABC',
    );
    final supplierB = SupplierSimpleResponse(
      supplierId: 2,
      supplierName: 'Công ty CP Acecook',
    );
    final supplierC = SupplierSimpleResponse(
      supplierId: 3,
      supplierName: 'Vinamilk',
    );

    final products = [
      ProductResponse(
        productId: 1,
        supplier: supplierA,
        productCode: 'SP001',
        productName: 'Bánh quy Cosy',
        minStockLevel: 10,
        price: 25000,
      ),
      ProductResponse(
        productId: 2,
        supplier: supplierA,
        productCode: 'SP002',
        productName: 'Nước ngọt Coca Cola',
        minStockLevel: 20,
        price: 12000,
      ),
      ProductResponse(
        productId: 3,
        supplier: supplierB,
        productCode: 'SP003',
        productName: 'Mì Hảo Hảo',
        minStockLevel: 30,
        price: 3500,
      ),
      ProductResponse(
        productId: 4,
        supplier: supplierC,
        productCode: 'SP004',
        productName: 'Sữa Vinamilk 1L',
        minStockLevel: 15,
        price: 28000,
      ),
    ];

    final batches = [
      InventoryBatchResponse(
        batchId: 1001,
        product: ProductSimpleResponse(productId: 1, productName: products[0].productName, productCode: products[0].productCode),
        importDate: DateTime(2026, 5, 2),
        expirationDate: DateTime(2026, 8, 20),
        quantity: 100,
        remainingQuantity: 45,
        status: 'Good',
      ),
      InventoryBatchResponse(
        batchId: 1002,
        product: ProductSimpleResponse(productId: 2, productName: products[1].productName, productCode: products[1].productCode),
        importDate: DateTime(2026, 5, 4),
        expirationDate: DateTime(2026, 7, 1),
        quantity: 120,
        remainingQuantity: 12,
        status: 'Low Stock',
      ),
      InventoryBatchResponse(
        batchId: 1003,
        product: ProductSimpleResponse(productId: 3, productName: products[2].productName, productCode: products[2].productCode),
        importDate: DateTime(2026, 4, 18),
        expirationDate: DateTime(2026, 5, 10),
        quantity: 80,
        remainingQuantity: 0,
        status: 'Expired',
      ),
      InventoryBatchResponse(
        batchId: 1004,
        product: ProductSimpleResponse(productId: 4, productName: products[3].productName, productCode: products[3].productCode),
        importDate: DateTime(2026, 5, 12),
        expirationDate: DateTime(2026, 6, 24),
        quantity: 60,
        remainingQuantity: 8,
        status: 'Low Stock',
      ),
    ];

    final transactions = [
      InventoryTransactionResponse(
        transactionId: 5001,
        batch: InventoryBatchSimpleResponse(batchId: 1001, remainingQuantity: 45, status: 'Good'),
        type: 'IMPORT',
        quantity: 100,
        createdAt: DateTime(2026, 5, 2, 9, 15),
      ),
      InventoryTransactionResponse(
        transactionId: 5002,
        batch: InventoryBatchSimpleResponse(batchId: 1002, remainingQuantity: 12, status: 'Low Stock'),
        type: 'EXPORT',
        quantity: 40,
        createdAt: DateTime(2026, 5, 20, 14, 30),
      ),
      InventoryTransactionResponse(
        transactionId: 5003,
        batch: InventoryBatchSimpleResponse(batchId: 1004, remainingQuantity: 8, status: 'Low Stock'),
        type: 'IMPORT',
        quantity: 60,
        createdAt: DateTime(2026, 5, 12, 8, 45),
      ),
    ];

    return InventoryDashboardData(
      products: products,
      batches: batches,
      transactions: transactions,
    );
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
        (batch) =>
            batch.status.toLowerCase() == 'low stock' ||
            batch.remainingQuantity <= 
            (products.firstWhere((p) => p.productId == batch.product?.productId, orElse: () => products.first).minStockLevel),
      )
      .length;
}
