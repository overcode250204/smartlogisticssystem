import 'inventory_batch_model.dart';

class InventoryTransactionModel {
  final int? transactionId;
  final InventoryBatchModel? batch;
  final int? batchId;
  final String? productName;
  final String type;
  final int quantity;
  final DateTime createdAt;

  const InventoryTransactionModel({
    this.transactionId,
    this.batch,
    this.batchId,
    this.productName,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    final batchJson = json['batch'];
    final productJson = json['product'];
    final batch = batchJson is Map<String, dynamic>
        ? InventoryBatchModel.fromJson(batchJson)
        : null;

    return InventoryTransactionModel(
      transactionId: json['transactionId'] as int?,
      batch: batch,
      batchId: json['batchId'] as int? ?? batch?.batchId,
      productName:
          json['productName']?.toString() ??
          (productJson is Map<String, dynamic>
              ? productJson['productName']?.toString()
              : null),
      type: json['type']?.toString() ?? 'IMPORT',
      quantity: json['quantity'] ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  int? get displayBatchId => batch?.batchId ?? batchId;

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'batch': batch?.toJson(),
      'batchId': batchId ?? batch?.batchId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
