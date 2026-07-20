import 'package:flutter/material.dart';

enum LocalTripDetailStatus { PENDING, ARRIVED, COMPLETED, FAILED }

extension LocalTripDetailStatusX on LocalTripDetailStatus {
  String get apiValue => name;

  String get label {
    switch (this) {
      case LocalTripDetailStatus.PENDING:
        return 'Chưa đến';
      case LocalTripDetailStatus.ARRIVED:
        return 'Đã đến nơi';
      case LocalTripDetailStatus.COMPLETED:
        return 'Giao thành công';
      case LocalTripDetailStatus.FAILED:
        return 'Giao thất bại';
    }
  }

  Color get color {
    switch (this) {
      case LocalTripDetailStatus.PENDING:
        return const Color(0xFF6B7280);
      case LocalTripDetailStatus.ARRIVED:
        return const Color(0xFF2563EB);
      case LocalTripDetailStatus.COMPLETED:
        return const Color(0xFF16A34A);
      case LocalTripDetailStatus.FAILED:
        return const Color(0xFFDC2626);
    }
  }

  static LocalTripDetailStatus fromApiValue(String value) {
    return LocalTripDetailStatus.values.firstWhere(
      (status) => status.apiValue == value.toUpperCase(),
      orElse: () => LocalTripDetailStatus.PENDING,
    );
  }
}
