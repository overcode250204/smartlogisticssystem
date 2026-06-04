import 'supplier_response_model.dart';

class ProductResponse {
  final int productId;
  final SupplierSimpleResponse? supplier;
  final String productCode;
  final String productName;
  final int minStockLevel;
  final double price;

  const ProductResponse({
    required this.productId,
    this.supplier,
    required this.productCode,
    required this.productName,
    required this.minStockLevel,
    required this.price,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      productId: json['productId'] as int? ?? 0,
      supplier: json['supplier'] != null 
          ? SupplierSimpleResponse.fromJson(json['supplier'])
          : null,
      productCode: json['productCode']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      minStockLevel: json['minStockLevel'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
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
