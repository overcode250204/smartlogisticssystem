class CustomerAddressModel {
  final int addressId;
  final String receiverName;
  final String phone;
  final int provinceCode;
  final String provinceName;
  final String deliveryAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String label;

  const CustomerAddressModel({
    required this.addressId,
    required this.receiverName,
    required this.phone,
    required this.provinceCode,
    required this.provinceName,
    required this.deliveryAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.label,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      addressId: (json['addressId'] as num?)?.toInt() ?? 0,
      receiverName: json['receiverName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      provinceCode: (json['provinceCode'] as num?)?.toInt() ?? 0,
      provinceName: json['provinceName'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      label: json['label'] as String? ?? 'Nhà riêng',
    );
  }
}

class CustomerAddressRequest {
  final String receiverName;
  final String phone;
  final int provinceCode;
  final String provinceName;
  final String deliveryAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String label;

  const CustomerAddressRequest({
    required this.receiverName,
    required this.phone,
    required this.provinceCode,
    required this.provinceName,
    required this.deliveryAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'receiverName': receiverName,
    'phone': phone,
    'provinceCode': provinceCode,
    'provinceName': provinceName,
    'deliveryAddress': deliveryAddress,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
    'label': label,
  };
}
