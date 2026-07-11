import 'package:smartlogisticssystem/data/model/order_model.dart';

class PalletItemModel {
  final int? id;
  final OrderModel? order;
  final String? scannedAt;

  PalletItemModel({
    this.id,
    this.order,
    this.scannedAt,
  });

  factory PalletItemModel.fromJson(Map<String, dynamic> json) {
    return PalletItemModel(
      id: _toInt(json['id']),
      order: json['order'] != null ? OrderModel.fromJson(json['order']) : null,
      scannedAt: json['scannedAt'],
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
