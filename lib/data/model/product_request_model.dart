class ProductCreateRequest {
  final int supplierId;
  final String productName;
  final int minStockLevel;
  final double price;

  const ProductCreateRequest({
    required this.supplierId,
    required this.productName,
    required this.minStockLevel,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'productName': productName,
      'minStockLevel': minStockLevel,
      'price': price,
    };
  }
}

class ProductUpdateRequest {
  final int? supplierId;
  final String? productCode;
  final String? productName;
  final int? minStockLevel;
  final double? price;

  const ProductUpdateRequest({
    this.supplierId,
    this.productCode,
    this.productName,
    this.minStockLevel,
    this.price,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (supplierId != null) data['supplierId'] = supplierId;
    if (productCode != null) data['productCode'] = productCode;
    if (productName != null) data['productName'] = productName;
    if (minStockLevel != null) data['minStockLevel'] = minStockLevel;
    if (price != null) data['price'] = price;
    return data;
  }
}
