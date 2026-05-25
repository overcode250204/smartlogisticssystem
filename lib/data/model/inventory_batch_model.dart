import 'product_model.dart';

class InventoryBatchModel {
  final int? batchId;
  final ProductModel? product;
  final int? productId;
  final String? productName;
  final int? requestedQuantity;
  final int? exportedQuantity;
  final DateTime importDate;
  final DateTime expirationDate;
  final int quantity;
  final int remainingQuantity;
  final String status;

  const InventoryBatchModel({
    this.batchId,
    this.product,
    this.productId,
    this.productName,
    this.requestedQuantity,
    this.exportedQuantity,
    required this.importDate,
    required this.expirationDate,
    required this.quantity,
    required this.remainingQuantity,
    required this.status,
  });

  factory InventoryBatchModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final product = productJson is Map<String, dynamic>
        ? ProductModel.fromJson(productJson)
        : null;

    return InventoryBatchModel(
      batchId: json['batchId'] as int?,
      product: product,
      productId: json['productId'] as int? ?? product?.productId,
      productName: json['productName']?.toString() ?? product?.productName,
      requestedQuantity: _parseInt(json['requestedQuantity']),
      exportedQuantity: _parseInt(json['exportedQuantity']),
      importDate: _parseDateTime(json['importDate']),
      expirationDate: _parseDateTime(json['expirationDate']),
      quantity: json['quantity'] ?? 0,
      remainingQuantity: json['remainingQuantity'] ?? 0,
      status: json['status'] ?? 'Good',
    );
  }

  String get displayProductName =>
      product?.productName ?? productName ?? 'SP$productId';

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'product': product?.toJson(),
      'productId': productId ?? product?.productId,
      'productName': productName ?? product?.productName,
      'requestedQuantity': requestedQuantity,
      'exportedQuantity': exportedQuantity,
      'importDate': importDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'status': status,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
