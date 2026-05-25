import 'product_response_model.dart';

class InventoryBatchResponse {
  final int batchId;
  final ProductSimpleResponse? product;
  final int? requestedQuantity;
  final int? exportedQuantity;
  final DateTime importDate;
  final DateTime expirationDate;
  final int quantity;
  final int remainingQuantity;
  final String status;

  const InventoryBatchResponse({
    required this.batchId,
    this.product,
    this.requestedQuantity,
    this.exportedQuantity,
    required this.importDate,
    required this.expirationDate,
    required this.quantity,
    required this.remainingQuantity,
    required this.status,
  });

  factory InventoryBatchResponse.fromJson(Map<String, dynamic> json) {
    return InventoryBatchResponse(
      batchId: json['batchId'] as int? ?? 0,
      product: json['product'] != null 
          ? ProductSimpleResponse.fromJson(json['product'])
          : null,
      requestedQuantity: _parseInt(json['requestedQuantity']),
      exportedQuantity: _parseInt(json['exportedQuantity']),
      importDate: _parseDateTime(json['importDate']) ?? DateTime.now(),
      expirationDate: _parseDateTime(json['expirationDate']) ?? DateTime.now(),
      quantity: json['quantity'] as int? ?? 0,
      remainingQuantity: json['remainingQuantity'] as int? ?? 0,
      status: json['status']?.toString() ?? 'Good',
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

class InventoryBatchSimpleResponse {
  final int batchId;
  final String? productName;
  final int remainingQuantity;
  final String status;

  const InventoryBatchSimpleResponse({
    required this.batchId,
    this.productName,
    required this.remainingQuantity,
    required this.status,
  });

  factory InventoryBatchSimpleResponse.fromJson(Map<String, dynamic> json) {
    return InventoryBatchSimpleResponse(
      batchId: json['batchId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? json['product']?['productName']?.toString(),
      remainingQuantity: json['remainingQuantity'] as int? ?? 0,
      status: json['status']?.toString() ?? 'Good',
    );
  }
}
