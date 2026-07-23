class InventoryTransactionCreateRequest {
  final int batchId;
  final String type;
  final int quantity;

  const InventoryTransactionCreateRequest({
    required this.batchId,
    required this.type,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'type': type,
      'quantity': quantity,
    };
  }
}

class InventoryTransactionUpdateRequest {
  final int? batchId;
  final String? type;
  final int? quantity;

  const InventoryTransactionUpdateRequest({
    this.batchId,
    this.type,
    this.quantity,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (batchId != null) data['batchId'] = batchId;
    if (type != null) data['type'] = type;
    if (quantity != null) data['quantity'] = quantity;
    return data;
  }
}
