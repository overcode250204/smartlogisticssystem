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
      productName: json['productName']?.toString() ??
          json['product']?['productName']?.toString(),
      remainingQuantity: json['remainingQuantity'] as int? ?? 0,
      status: json['status']?.toString() ?? 'Good',
    );
  }
}

class InventoryExportResponse {
  final ProductSimpleResponse? product;
  final int requestedQuantity;
  final int exportedQuantity;
  final int remainingStock;
  final List<InventoryExportBatch> batches;

  const InventoryExportResponse({
    this.product,
    required this.requestedQuantity,
    required this.exportedQuantity,
    required this.remainingStock,
    required this.batches,
  });

  factory InventoryExportResponse.fromJson(Map<String, dynamic> json) {
    return InventoryExportResponse(
      product: json['product'] != null
          ? ProductSimpleResponse.fromJson(json['product'])
          : null,
      requestedQuantity:
          InventoryBatchResponse._parseInt(json['requestedQuantity']) ?? 0,
      exportedQuantity:
          InventoryBatchResponse._parseInt(json['exportedQuantity']) ?? 0,
      remainingStock:
          InventoryBatchResponse._parseInt(json['remainingStock']) ?? 0,
      batches: json['batches'] is List
          ? (json['batches'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => InventoryExportBatch.fromJson(item))
              .toList()
          : const [],
    );
  }
}

class InventoryExportBatch {
  final int batchId;
  final int exportedQuantity;
  final int remainingQuantity;

  const InventoryExportBatch({
    required this.batchId,
    required this.exportedQuantity,
    required this.remainingQuantity,
  });

  factory InventoryExportBatch.fromJson(Map<String, dynamic> json) {
    return InventoryExportBatch(
      batchId: InventoryBatchResponse._parseInt(json['batchId']) ?? 0,
      exportedQuantity:
          InventoryBatchResponse._parseInt(json['exportedQuantity']) ?? 0,
      remainingQuantity:
          InventoryBatchResponse._parseInt(json['remainingQuantity']) ?? 0,
    );
  }
}
