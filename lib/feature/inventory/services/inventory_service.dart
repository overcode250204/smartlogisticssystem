import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_model.dart';
import 'package:smartlogisticssystem/data/model/product_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_model.dart';
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

      final products = results[0] as List<ProductModel>;
      final batches = _attachProducts(
        results[1] as List<InventoryBatchModel>,
        products,
      );

      return InventoryDashboardData(
        products: products,
        batches: batches,
        transactions: results[2] as List<InventoryTransactionModel>,
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

  List<InventoryBatchModel> _attachProducts(
    List<InventoryBatchModel> batches,
    List<ProductModel> products,
  ) {
    return batches.map((batch) {
      if (batch.product != null) return batch;
      final product = products
          .where((item) => item.productId == batch.productId)
          .cast<ProductModel?>()
          .firstWhere((item) => item != null, orElse: () => null);

      return InventoryBatchModel(
        batchId: batch.batchId,
        product: product,
        productId: batch.productId,
        importDate: batch.importDate,
        expirationDate: batch.expirationDate,
        quantity: batch.quantity,
        remainingQuantity: batch.remainingQuantity,
        status: batch.status,
      );
    }).toList();
  }

  InventoryDashboardData mockDashboardData() {
    final supplierA = SupplierModel(
      supplierId: 1,
      supplierName: 'Công ty TNHH ABC',
      contactPhone: '0901000001',
      address: 'TP. Hồ Chí Minh',
      createdAt: DateTime(2026, 1, 10),
    );
    final supplierB = SupplierModel(
      supplierId: 2,
      supplierName: 'Công ty CP Acecook',
      contactPhone: '0901000002',
      address: 'Bình Dương',
      createdAt: DateTime(2026, 1, 12),
    );
    final supplierC = SupplierModel(
      supplierId: 3,
      supplierName: 'Vinamilk',
      contactPhone: '0901000003',
      address: 'TP. Hồ Chí Minh',
      createdAt: DateTime(2026, 1, 15),
    );

    final products = [
      ProductModel(
        productId: 1,
        supplier: supplierA,
        supplierId: 1,
        productCode: 'SP001',
        productName: 'Bánh quy Cosy',
        minStockLevel: 10,
        price: 25000,
      ),
      ProductModel(
        productId: 2,
        supplier: supplierA,
        supplierId: 1,
        productCode: 'SP002',
        productName: 'Nước ngọt Coca Cola',
        minStockLevel: 20,
        price: 12000,
      ),
      ProductModel(
        productId: 3,
        supplier: supplierB,
        supplierId: 2,
        productCode: 'SP003',
        productName: 'Mì Hảo Hảo',
        minStockLevel: 30,
        price: 3500,
      ),
      ProductModel(
        productId: 4,
        supplier: supplierC,
        supplierId: 3,
        productCode: 'SP004',
        productName: 'Sữa Vinamilk 1L',
        minStockLevel: 15,
        price: 28000,
      ),
    ];

    final batches = [
      InventoryBatchModel(
        batchId: 1001,
        product: products[0],
        productId: 1,
        importDate: DateTime(2026, 5, 2),
        expirationDate: DateTime(2026, 8, 20),
        quantity: 100,
        remainingQuantity: 45,
        status: 'Good',
      ),
      InventoryBatchModel(
        batchId: 1002,
        product: products[1],
        productId: 2,
        importDate: DateTime(2026, 5, 4),
        expirationDate: DateTime(2026, 7, 1),
        quantity: 120,
        remainingQuantity: 12,
        status: 'Low Stock',
      ),
      InventoryBatchModel(
        batchId: 1003,
        product: products[2],
        productId: 3,
        importDate: DateTime(2026, 4, 18),
        expirationDate: DateTime(2026, 5, 10),
        quantity: 80,
        remainingQuantity: 0,
        status: 'Expired',
      ),
      InventoryBatchModel(
        batchId: 1004,
        product: products[3],
        productId: 4,
        importDate: DateTime(2026, 5, 12),
        expirationDate: DateTime(2026, 6, 24),
        quantity: 60,
        remainingQuantity: 8,
        status: 'Low Stock',
      ),
    ];

    final transactions = [
      InventoryTransactionModel(
        transactionId: 5001,
        batch: batches[0],
        batchId: 1001,
        type: 'IMPORT',
        quantity: 100,
        createdAt: DateTime(2026, 5, 2, 9, 15),
      ),
      InventoryTransactionModel(
        transactionId: 5002,
        batch: batches[1],
        batchId: 1002,
        type: 'EXPORT',
        quantity: 40,
        createdAt: DateTime(2026, 5, 20, 14, 30),
      ),
      InventoryTransactionModel(
        transactionId: 5003,
        batch: batches[3],
        batchId: 1004,
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
  final List<ProductModel> products;
  final List<InventoryBatchModel> batches;
  final List<InventoryTransactionModel> transactions;

  const InventoryDashboardData({
    required this.products,
    required this.batches,
    required this.transactions,
  });

  int get lowStockCount => batches
      .where(
        (batch) =>
            batch.status.toLowerCase() == 'low stock' ||
            batch.remainingQuantity <= (batch.product?.minStockLevel ?? 0),
      )
      .length;
}
