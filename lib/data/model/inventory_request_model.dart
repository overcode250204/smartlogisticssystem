class InventoryCreateRequest {
  final int productId;
  final int quantity;
  final int minStockLevel;

  const InventoryCreateRequest({
    required this.productId,
    required this.quantity,
    required this.minStockLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
    };
  }
}

class InventoryUpdateRequest {
  final int? productId;
  final int? quantity;
  final int? minStockLevel;

  const InventoryUpdateRequest({
    this.productId,
    this.quantity,
    this.minStockLevel,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (productId != null) data['productId'] = productId;
    if (quantity != null) data['quantity'] = quantity;
    if (minStockLevel != null) data['minStockLevel'] = minStockLevel;
    return data;
  }
}
