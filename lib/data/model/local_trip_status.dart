import 'package:flutter/material.dart';

enum LocalTripStatus {
  PENDING_ACCEPTANCE,
  ACCEPTED,
  CANCELLED,
  ASSIGNED,
  EXECUTING,
  COMPLETED,
}

extension LocalTripStatusX on LocalTripStatus {
  String get apiValue => name;

  String get label {
    switch (this) {
      case LocalTripStatus.PENDING_ACCEPTANCE:
        return 'Chờ nhận chuyến';
      case LocalTripStatus.ACCEPTED:
        return 'Đã nhận, chờ quét mã';
      case LocalTripStatus.CANCELLED:
        return 'Đã huỷ';
      case LocalTripStatus.ASSIGNED:
        return 'Đang chờ sắp xếp lại';
      case LocalTripStatus.EXECUTING:
        return 'Đang giao hàng';
      case LocalTripStatus.COMPLETED:
        return 'Đã hoàn thành';
    }
  }

  Color get color {
    switch (this) {
      case LocalTripStatus.PENDING_ACCEPTANCE:
        return const Color(0xFFF97316);
      case LocalTripStatus.ACCEPTED:
        return const Color(0xFF2563EB);
      case LocalTripStatus.CANCELLED:
        return const Color(0xFFDC2626);
      case LocalTripStatus.ASSIGNED:
        return const Color(0xFF6B7280);
      case LocalTripStatus.EXECUTING:
        return const Color(0xFF7C3AED);
      case LocalTripStatus.COMPLETED:
        return const Color(0xFF16A34A);
    }
  }

  static LocalTripStatus fromApiValue(String value) {
    return LocalTripStatus.values.firstWhere(
      (status) => status.apiValue == value.toUpperCase(),
      orElse: () => LocalTripStatus.PENDING_ACCEPTANCE,
    );
  }
}
