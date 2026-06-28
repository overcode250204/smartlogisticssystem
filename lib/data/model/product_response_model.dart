import 'supplier_response_model.dart';

class ProductPageResponse {
  final List<ProductResponse> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const ProductPageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory ProductPageResponse.fromJson(Map<String, dynamic> json) {
    return ProductPageResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 10,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? false,
    );
  }
}

class ProductResponse {
  final int productId;
  final SupplierSimpleResponse? supplier;
  final String productCode;
  final String productName;
  final String sku;
  final int? categoryId;
  final String? categoryName;
  final int minStockLevel;
  final double price;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final String? imageUrl;
  final int? baseUnitId;
  final String? baseUnitCode;
  final String? baseUnitName;

  const ProductResponse({
    required this.productId,
    this.supplier,
    required this.productCode,
    required this.productName,
    required this.sku,
    this.categoryId,
    this.categoryName,
    required this.minStockLevel,
    required this.price,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.imageUrl,
    this.baseUnitId,
    this.baseUnitCode,
    this.baseUnitName,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'] as Map<String, dynamic>?;
    final categoryJson = json['category'] as Map<String, dynamic>?;
    final baseUnitJson = json['baseUnit'] as Map<String, dynamic>?;

    return ProductResponse(
      productId: json['productId'] as int? ?? 0,
      supplier: supplierJson != null ? SupplierSimpleResponse.fromJson(supplierJson) : null,
      productCode: json['productCode']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      categoryId: categoryJson != null ? categoryJson['categoryId'] as int? : json['categoryId'] as int?,
      categoryName: categoryJson != null ? categoryJson['categoryName']?.toString() : json['categoryName']?.toString(),
      minStockLevel: json['minStockLevel'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      imageUrl: json['imageUrl']?.toString(),
      baseUnitId: baseUnitJson != null ? baseUnitJson['unitId'] as int? : json['baseUnitId'] as int?,
      baseUnitCode: baseUnitJson != null ? baseUnitJson['unitCode']?.toString() : json['baseUnitCode']?.toString(),
      baseUnitName: baseUnitJson != null ? baseUnitJson['unitName']?.toString() : json['baseUnitName']?.toString(),
    );
  }
}

class ProductSimpleResponse {
  final int productId;
  final String productName;
  final String productCode;

  const ProductSimpleResponse({
    required this.productId,
    required this.productName,
    required this.productCode,
  });

  factory ProductSimpleResponse.fromJson(Map<String, dynamic> json) {
    return ProductSimpleResponse(
      productId: json['productId'] as int? ?? 0,
      productName: json['productName']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
    );
  }
}
