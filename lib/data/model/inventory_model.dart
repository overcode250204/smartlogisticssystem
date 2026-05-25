class InventoryModel {
  final int? productId;
  final String? productCode;
  final String? productName;
  final int? minStockLevel;
  final double? price;
  final int? supplierId;
  final String? supplierName;
  final String? contactPhone;
  final String? address;
  final int? batchId;
  final DateTime? importDate;
  final DateTime? expirationDate;
  final int? quantity;
  final int? remainingQuantity;
  final String? status;
  final int? transactionId;
  final String? type;
  final DateTime? createdAt;
  final int? requestedQuantity;
  final int? exportedQuantity;
  final DateTime? exportDate;
  final int? remainingStock;
  final InventoryModel? supplier;
  final InventoryModel? product;
  final List<InventoryModel>? batches;

  InventoryModel({
    this.productId,
    this.productCode,
    this.productName,
    this.minStockLevel,
    this.price,
    this.supplierId,
    this.supplierName,
    this.contactPhone,
    this.address,
    this.batchId,
    this.importDate,
    this.expirationDate,
    this.quantity,
    this.remainingQuantity,
    this.status,
    this.transactionId,
    this.type,
    this.createdAt,
    this.requestedQuantity,
    this.exportedQuantity,
    this.exportDate,
    this.remainingStock,
    this.supplier,
    this.product,
    this.batches,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      productId: _parseInt(json['productId']),
      productCode: json['productCode']?.toString(),
      productName: json['productName']?.toString(),
      minStockLevel: _parseInt(json['minStockLevel']),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      supplierId: _parseInt(json['supplierId']),
      supplierName: json['supplierName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      address: json['address']?.toString(),
      batchId: _parseInt(json['batchId']),
      importDate: _parseDateTime(json['importDate']),
      expirationDate: _parseDateTime(json['expirationDate']),
      quantity: _parseInt(json['quantity']),
      remainingQuantity: _parseInt(json['remainingQuantity']),
      status: json['status']?.toString(),
      transactionId: _parseInt(json['transactionId']),
      type: json['type']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      requestedQuantity: _parseInt(json['requestedQuantity']),
      exportedQuantity: _parseInt(json['exportedQuantity']),
      exportDate: _parseDateTime(json['exportDate']),
      remainingStock: _parseInt(json['remainingStock']),
      supplier: json['supplier'] is Map<String, dynamic>
          ? InventoryModel.fromJson(json['supplier'])
          : null,
      product: json['product'] is Map<String, dynamic>
          ? InventoryModel.fromJson(json['product'])
          : null,
      batches: json['batches'] is List
          ? (json['batches'] as List)
              .whereType<Map<String, dynamic>>()
              .map(InventoryModel.fromJson)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'minStockLevel': minStockLevel,
      'price': price,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'contactPhone': contactPhone,
      'address': address,
      'batchId': batchId,
      'importDate': importDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'status': status,
      'transactionId': transactionId,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
      'requestedQuantity': requestedQuantity,
      'exportedQuantity': exportedQuantity,
      'exportDate': exportDate?.toIso8601String(),
      'remainingStock': remainingStock,
      'supplier': supplier?.toJson(),
      'product': product?.toJson(),
      'batches': batches?.map((e) => e.toJson()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
