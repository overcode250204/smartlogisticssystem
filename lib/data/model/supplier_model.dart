class SupplierModel {
  final int? supplierId;
  final String supplierName;
  final String? contactPhone;
  final String? address;
  final DateTime? createdAt;

  const SupplierModel({
    this.supplierId,
    required this.supplierName,
    this.contactPhone,
    this.address,
    this.createdAt,
  });

  factory SupplierModel.empty() {
    return const SupplierModel(supplierName: '');
  }

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'] ?? json['name'] ?? '',
      contactPhone: json['contactPhone'],
      address: json['address'],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'contactPhone': contactPhone,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
