class SupplierCreateRequest {
  final String supplierName;
  final String? contactPhone;
  final String? address;

  const SupplierCreateRequest({
    required this.supplierName,
    this.contactPhone,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierName': supplierName,
      'contactPhone': contactPhone,
      'address': address,
    };
  }
}

class SupplierUpdateRequest {
  final String? supplierName;
  final String? contactPhone;
  final String? address;

  const SupplierUpdateRequest({
    this.supplierName,
    this.contactPhone,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (supplierName != null) data['supplierName'] = supplierName;
    if (contactPhone != null) data['contactPhone'] = contactPhone;
    if (address != null) data['address'] = address;
    return data;
  }
}
