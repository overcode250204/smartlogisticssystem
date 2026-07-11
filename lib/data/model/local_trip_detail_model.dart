import 'package:smartlogisticssystem/data/model/order_model.dart';

class LocalTripDetailModel {
  final int? id;
  final OrderModel? order;
  final int? stopOrder;
  final String? proofUrl;
  final bool? barcodeScanned;
  final String? status;

  LocalTripDetailModel({
    this.id,
    this.order,
    this.stopOrder,
    this.proofUrl,
    this.barcodeScanned,
    this.status,
  });

  factory LocalTripDetailModel.fromJson(Map<String, dynamic> json) {
    return LocalTripDetailModel(
      id: _toInt(json['id']),
      order: json['order'] != null ? OrderModel.fromJson(json['order']) : null,
      stopOrder: _toInt(json['stopOrder']),
      proofUrl: json['proofUrl'],
      barcodeScanned: json['barcodeScanned'],
      status: json['status'],
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
