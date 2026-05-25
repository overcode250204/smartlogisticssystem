class InventoryBatchCreateRequest {
  final int productId;
  final DateTime importDate;
  final DateTime expirationDate;
  final int quantity;
  final int remainingQuantity;
  final String status;

  const InventoryBatchCreateRequest({
    required this.productId,
    required this.importDate,
    required this.expirationDate,
    required this.quantity,
    required this.remainingQuantity,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'importDate': importDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'status': status,
    };
  }
}

class InventoryBatchUpdateRequest {
  final int? productId;
  final DateTime? importDate;
  final DateTime? expirationDate;
  final int? quantity;
  final int? remainingQuantity;
  final String? status;

  const InventoryBatchUpdateRequest({
    this.productId,
    this.importDate,
    this.expirationDate,
    this.quantity,
    this.remainingQuantity,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (productId != null) data['productId'] = productId;
    if (importDate != null) data['importDate'] = importDate!.toIso8601String();
    if (expirationDate != null) data['expirationDate'] = expirationDate!.toIso8601String();
    if (quantity != null) data['quantity'] = quantity;
    if (remainingQuantity != null) data['remainingQuantity'] = remainingQuantity;
    if (status != null) data['status'] = status;
    return data;
  }
}
