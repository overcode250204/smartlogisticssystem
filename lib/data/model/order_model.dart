import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';

class OrderModel {
  final int orderId;
  final String orderCode;
  final String? barcodeUrl;
  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String deliveryProvince;
  final double latitude;
  final double longitude;
  final WarehouseModel? assignedHub;
  final RouteConfigModel? routeConfig;
  final double totalAmount;
  final String paymentType;
  final String status;
  final double totalWeightKg;
  final double totalVolumeM3;
  final String createdAt;
  final List<OrderItemModel> items;
  final String? proofUrl;

  const OrderModel({
    required this.orderId,
    required this.orderCode,
    this.barcodeUrl,
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    required this.deliveryProvince,
    required this.latitude,
    required this.longitude,
    this.assignedHub,
    this.routeConfig,
    required this.totalAmount,
    required this.paymentType,
    required this.status,
    required this.totalWeightKg,
    required this.totalVolumeM3,
    required this.createdAt,
    required this.items,
    this.proofUrl,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode'] as String? ?? '',
      barcodeUrl: json['barcodeUrl'] as String?,
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      deliveryProvince: json['deliveryProvince'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      assignedHub: json['assignedHub'] != null
          ? WarehouseModel.fromJson(json['assignedHub'])
          : null,
      routeConfig: json['routeConfig'] != null
          ? RouteConfigModel.fromJson(json['routeConfig'])
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentType: json['paymentType'] as String? ?? 'COD',
      status: json['status'] as String? ?? 'NEW',
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
      totalVolumeM3: (json['totalVolumeM3'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e))
              .toList() ??
          const [],
      proofUrl: json['proofUrl'] as String?,
    );
  }
}

class OrderItemModel {
  final int itemId;
  final String productName;
  final int quantityOrdered;
  final int? quantityDelivered;
  final double unitPrice;
  final double weightKg;
  final double volumeM3;

  const OrderItemModel({
    required this.itemId,
    required this.productName,
    required this.quantityOrdered,
    this.quantityDelivered,
    required this.unitPrice,
    required this.weightKg,
    required this.volumeM3,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? '',
      quantityOrdered: (json['quantityOrdered'] as num?)?.toInt() ?? 0,
      quantityDelivered: (json['quantityDelivered'] as num?)?.toInt(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      volumeM3: (json['volumeM3'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderCreateRequest {
  final String customerName;
  final String phone;
  final String deliveryAddress;
  final String deliveryProvince;
  final double latitude;
  final double longitude;
  final String paymentType;
  final List<OrderItemRequest> items;

  const OrderCreateRequest({
    required this.customerName,
    required this.phone,
    required this.deliveryAddress,
    required this.deliveryProvince,
    required this.latitude,
    required this.longitude,
    required this.paymentType,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'phone': phone,
      'deliveryAddress': deliveryAddress,
      'deliveryProvince': deliveryProvince,
      'latitude': latitude,
      'longitude': longitude,
      'paymentType': paymentType,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItemRequest {
  final int productId;
  final int quantity;

  const OrderItemRequest({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
