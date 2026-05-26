class InvoiceResponse {
  final int invoiceId;
  final String invoiceType;
  final double totalAmount;
  final String createdByName;
  final int createdById;
  final DateTime? createdAt;

  const InvoiceResponse({
    required this.invoiceId,
    required this.invoiceType,
    required this.totalAmount,
    required this.createdByName,
    required this.createdById,
    this.createdAt,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return InvoiceResponse(
      invoiceId: json['invoiceId'] as int? ?? 0,
      invoiceType: json['invoiceType']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdByName: createdBy?['fullName']?.toString() ?? '',
      createdById: createdBy?['userId'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class DashboardStatsResponse {
  final double totalRevenueThisMonth;
  final int totalDeliveredOrders;
  final double damagedInventoryRatio;

  const DashboardStatsResponse({
    required this.totalRevenueThisMonth,
    required this.totalDeliveredOrders,
    required this.damagedInventoryRatio,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardStatsResponse(
      totalRevenueThisMonth:
          (json['totalRevenueThisMonth'] as num?)?.toDouble() ?? 0.0,
      totalDeliveredOrders: json['totalDeliveredOrders'] as int? ?? 0,
      damagedInventoryRatio:
          (json['damagedInventoryRatio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
