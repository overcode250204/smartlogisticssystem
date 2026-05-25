import 'product_response_model.dart';
import 'supplier_response_model.dart';
import 'inventory_batch_response_model.dart';

class InventoryResponse {
  final int inventoryId;
  final ProductSimpleResponse? product;
  final SupplierSimpleResponse? supplier;
  final int quantity;
  final int remainingStock;
  final int minStockLevel;
  final DateTime? createdAt;
  final List<InventoryBatchResponse>? batches;

  const InventoryResponse({
    required this.inventoryId,
    this.product,
    this.supplier,
    required this.quantity,
    required this.remainingStock,
    required this.minStockLevel,
    this.createdAt,
    this.batches,
  });

  factory InventoryResponse.fromJson(Map<String, dynamic> json) {
    return InventoryResponse(
      inventoryId: _parseInt(json['inventoryId']) ?? 0,
      product: json['product'] != null ? ProductSimpleResponse.fromJson(json['product']) : null,
      supplier: json['supplier'] != null ? SupplierSimpleResponse.fromJson(json['supplier']) : null,
      quantity: _parseInt(json['quantity']) ?? 0,
      remainingStock: _parseInt(json['remainingStock']) ?? 0,
      minStockLevel: _parseInt(json['minStockLevel']) ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      batches: json['batches'] is List
          ? (json['batches'] as List)
              .whereType<Map<String, dynamic>>()
              .map(InventoryBatchResponse.fromJson)
              .toList()
          : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
