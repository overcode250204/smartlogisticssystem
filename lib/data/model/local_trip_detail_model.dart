import 'package:smartlogisticssystem/data/model/order_model.dart';

enum LocalTripDetailStatus {
PENDING, 
ARRIVED, 
COMPLETED, 
FAILED;

  String get displayName {
    return switch (this) {
      LocalTripDetailStatus.PENDING => 'Đang xử lí',
      LocalTripDetailStatus.ARRIVED => 'Đã đến nơi',
      LocalTripDetailStatus.COMPLETED => 'Đã giao hàng',
      LocalTripDetailStatus.FAILED => 'Thất bại',
    };
  }
}

class LocalTripDetailModel {
  final int? id;
  final OrderModel? order;
  final int? stopOrder;
  final String? proofUrl;
  final bool? barcodeScanned;
  final LocalTripDetailStatus? status;
  final String? localTripDetailCode;

  LocalTripDetailModel({
    this.id,
    this.order,
    this.stopOrder,
    this.proofUrl,
    this.barcodeScanned,
    this.status,
    this.localTripDetailCode,
  });

  factory LocalTripDetailModel.fromJson(Map<String, dynamic> json) {
    return LocalTripDetailModel(
      id: _toInt(json['id']),
      order: json['order'] != null ? OrderModel.fromJson(json['order']) : null,
      stopOrder: _toInt(json['stopOrder']),
      proofUrl: json['proofUrl'],
      barcodeScanned: json['barcodeScanned'],
      status: json['status'] != null ? LocalTripDetailStatus.values.firstWhere((e) => e.name == json['status']) : null,
      localTripDetailCode: json['localTripDetailCode'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
