import 'inventory_batch_response_model.dart';

class InventoryTransactionResponse {
  final int transactionId;
  final InventoryBatchSimpleResponse? batch;
  final String type;
  final int quantity;
  final DateTime createdAt;

  const InventoryTransactionResponse({
    required this.transactionId,
    this.batch,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  factory InventoryTransactionResponse.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionResponse(
      transactionId: json['transactionId'] as int? ?? 0,
      batch: json['batch'] != null 
          ? InventoryBatchSimpleResponse.fromJson(json['batch'])
          : null,
      type: json['type']?.toString() ?? 'IMPORT',
      quantity: json['quantity'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
