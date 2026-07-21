import 'package:smartlogisticssystem/data/model/driver_model.dart';

enum role{
  MAIN,ASSISTANT;
  String get displayName {
    return switch (this) {
      role.MAIN => 'Tài xế chính',
      role.ASSISTANT => 'Tài xế phụ',
    };
  }
}

class LinehaulTripDriverModel {
  final int? id;
  final DriverModel? driver;
  final String? role;
  final String? assignedAt;

  LinehaulTripDriverModel({
    this.id,
    this.driver,
    this.role,
    this.assignedAt,
  });

  factory LinehaulTripDriverModel.fromJson(Map<String, dynamic> json) {
    return LinehaulTripDriverModel(
      id: _toInt(json['id']),
      driver: json['driver'] != null ? DriverModel.fromJson(json['driver']) : null,
      role: json['role'],
      assignedAt: json['assignedAt'],
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
