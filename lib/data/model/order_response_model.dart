class OrderResponse {
  final int orderId;
  final String orderCode;
  final String? barcodeUrl;
  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String? deliveryProvince;
  final double? latitude;
  final double? longitude;
  final double totalAmount;
  final String? paymentType;
  final String? status;
  final String? proofUrl;
  final DateTime? expectedDeliveryTime;
  final DateTime? actualDeliveryTime;

  const OrderResponse({
    required this.orderId,
    required this.orderCode,
    this.barcodeUrl,
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    this.deliveryProvince,
    this.latitude,
    this.longitude,
    required this.totalAmount,
    this.paymentType,
    this.status,
    this.proofUrl,
    this.expectedDeliveryTime,
    this.actualDeliveryTime,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderId: _parseInt(json['orderId']) ?? 0,
      orderCode: json['orderCode']?.toString() ?? '',
      barcodeUrl: json['barcodeUrl']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      deliveryProvince: json['deliveryProvince']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      totalAmount: _parseDouble(json['totalAmount']) ?? 0,
      paymentType: json['paymentType']?.toString(),
      status: json['status']?.toString(),
      proofUrl: json['proofUrl']?.toString(),
      expectedDeliveryTime: _parseDateTime(json['expectedDeliveryTime']),
      actualDeliveryTime: _parseDateTime(json['actualDeliveryTime']),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
