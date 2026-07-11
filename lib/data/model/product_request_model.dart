class ProductCreateRequest {
  final String productName;
  final String? sku;
  final double price;
  final double weight;
  final double? length;
  final double? width;
  final double? height;

  // Bắt buộc khi tạo Product.
  final int baseUnitId;

  final int? minStockLevel;
  final int supplierId;
  final int categoryId;

  const ProductCreateRequest({
    required this.productName,
    this.sku,
    required this.price,
    required this.weight,
    this.length,
    this.width,
    this.height,
    required this.baseUnitId,
    this.minStockLevel,
    required this.supplierId,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName.trim(),
      if (sku != null && sku!.trim().isNotEmpty) 'sku': sku!.trim(),
      'price': price,
      'weight': weight,
      if (length != null) 'length': length,
      if (width != null) 'width': width,
      if (height != null) 'height': height,

      // Luôn gửi ID Unit đã chọn cho Product.baseUnit.
      'baseUnitId': baseUnitId,

      if (minStockLevel != null) 'minStockLevel': minStockLevel,
      'supplierId': supplierId,
      'categoryId': categoryId,
    };
  }
}

class ProductUpdateRequest {
  final int? supplierId;
  final int? categoryId;
  final String? productCode;
  final String? productName;
  final String? sku;
  final double? price;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final int? baseUnitId;
  final int? minStockLevel;

  const ProductUpdateRequest({
    this.supplierId,
    this.categoryId,
    this.productCode,
    this.productName,
    this.sku,
    this.price,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.baseUnitId,
    this.minStockLevel,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (supplierId != null) data['supplierId'] = supplierId;
    if (categoryId != null) data['categoryId'] = categoryId;

    if (productCode != null && productCode!.trim().isNotEmpty) {
      data['productCode'] = productCode!.trim();
    }

    if (productName != null && productName!.trim().isNotEmpty) {
      data['productName'] = productName!.trim();
    }

    if (sku != null) {
      data['sku'] = sku!.trim();
    }

    if (price != null) data['price'] = price;
    if (weight != null) data['weight'] = weight;
    if (length != null) data['length'] = length;
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (baseUnitId != null) data['baseUnitId'] = baseUnitId;
    if (minStockLevel != null) data['minStockLevel'] = minStockLevel;

    return data;
  }
}
