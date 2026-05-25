import 'supplier_model.dart';

class ProductModel {
  final int? productId;
  final SupplierModel? supplier;
  final int? supplierId;
  final String productCode;
  final String productName;
  final int minStockLevel;
  final double price;

  const ProductModel({
    this.productId,
    this.supplier,
    this.supplierId,
    required this.productCode,
    required this.productName,
    required this.minStockLevel,
    required this.price,
  });

  factory ProductModel.empty() {
    return const ProductModel(
      productCode: '',
      productName: '',
      minStockLevel: 0,
      price: 0,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'];
    final supplierName = json['supplierName'];

    return ProductModel(
      productId: json['productId'] as int?,
      supplier: supplierJson is Map<String, dynamic>
          ? SupplierModel.fromJson(supplierJson)
          : supplierName != null
          ? SupplierModel(
              supplierId: json['supplierId'] as int?,
              supplierName: supplierName.toString(),
            )
          : null,
      supplierId:
          json['supplierId'] as int? ??
          (supplierJson is Map<String, dynamic>
              ? supplierJson['supplierId'] as int?
              : null),
      productCode: json['productCode'] ?? '',
      productName: json['productName'] ?? '',
      minStockLevel: json['minStockLevel'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  String get supplierName => supplier?.supplierName ?? '';

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'supplierId': supplierId ?? supplier?.supplierId,
      'productCode': productCode,
      'productName': productName,
      'minStockLevel': minStockLevel,
      'price': price,
    };
  }
}
