import 'package:smartlogisticssystem/data/model/order_model.dart';

class PalletItemModel {
  final int? id;
  final OrderModel? order;
  final bool isScanned;
  final String? scannedAt;

  PalletItemModel({
    this.id,
    this.order,
    this.isScanned = false,
    this.scannedAt,
  });

  factory PalletItemModel.fromJson(Map<String, dynamic> json) {
    return PalletItemModel(
      id: _toInt(json['id']),
      order: json['order'] != null ? OrderModel.fromJson(json['order']) : null,
      isScanned: _toBool(json['isScanned']) ?? json['scannedAt'] != null,
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

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }
}
