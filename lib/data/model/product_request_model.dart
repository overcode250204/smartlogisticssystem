class ProductCreateRequest {
  final int supplierId;
  final int categoryId;
  final String productName;
  final int minStockLevel;
  final double price;
  final double weight;

  const ProductCreateRequest({
    required this.supplierId,
    required this.categoryId,
    required this.productName,
    required this.minStockLevel,
    required this.price,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'categoryId': categoryId,
      'productName': productName,
      'minStockLevel': minStockLevel,
      'price': price,
      'weight': weight,
    };
  }
}

class ProductUpdateRequest {
  final int? supplierId;
  final int? categoryId;
  final String? productCode;
  final String? productName;
  final int? minStockLevel;
  final double? price;
  final double? weight;

  const ProductUpdateRequest({
    this.supplierId,
    this.categoryId,
    this.productCode,
    this.productName,
    this.minStockLevel,
    this.price,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (supplierId != null) data['supplierId'] = supplierId;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (productCode != null) data['productCode'] = productCode;
    if (productName != null) data['productName'] = productName;
    if (minStockLevel != null) data['minStockLevel'] = minStockLevel;
    if (price != null) data['price'] = price;
    if (weight != null) data['weight'] = weight;
    return data;
  }
}
