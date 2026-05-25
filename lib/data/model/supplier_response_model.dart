class SupplierResponse {
  final int supplierId;
  final String supplierName;
  final String? contactPhone;
  final String? address;
  final DateTime? createdAt;

  const SupplierResponse({
    required this.supplierId,
    required this.supplierName,
    this.contactPhone,
    this.address,
    this.createdAt,
  });

  factory SupplierResponse.fromJson(Map<String, dynamic> json) {
    return SupplierResponse(
      supplierId: json['supplierId'] as int? ?? 0,
      supplierName: json['supplierName']?.toString() ?? json['name']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString(),
      address: json['address']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class SupplierSimpleResponse {
  final int supplierId;
  final String supplierName;

  const SupplierSimpleResponse({
    required this.supplierId,
    required this.supplierName,
  });

  factory SupplierSimpleResponse.fromJson(Map<String, dynamic> json) {
    return SupplierSimpleResponse(
      supplierId: json['supplierId'] as int? ?? 0,
      supplierName: json['supplierName']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}
