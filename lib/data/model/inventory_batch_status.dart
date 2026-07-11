enum InventoryBatchStatus {
  GOOD,
  OUT_OF_STOCK,
  EXPIRING_SOON,
  LOW_STOCK,
  NORMAL
}

extension InventoryBatchStatusX on InventoryBatchStatus {
  String get apiValue => name; // e.g. "GOOD", "OUT_OF_STOCK"

  static bool isValidApiValue(String value) {
    return InventoryBatchStatus.values.any((status) => status.apiValue == value);
  }

  String get label {
    switch (this) {
      case InventoryBatchStatus.GOOD:
        return 'Tốt';
      case InventoryBatchStatus.OUT_OF_STOCK:
        return 'Hết hàng';
      case InventoryBatchStatus.EXPIRING_SOON:
        return 'Sắp hết hạn';
      case InventoryBatchStatus.LOW_STOCK:
        return 'Tồn kho thấp';
      case InventoryBatchStatus.NORMAL:
        return 'Bình thường';
    }
  }

  static InventoryBatchStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'GOOD':
        return InventoryBatchStatus.GOOD;
      case 'OUT_OF_STOCK':
        return InventoryBatchStatus.OUT_OF_STOCK;
      case 'EXPIRING_SOON':
        return InventoryBatchStatus.EXPIRING_SOON;
      case 'LOW_STOCK':
        return InventoryBatchStatus.LOW_STOCK;
      case 'NORMAL':
        return InventoryBatchStatus.NORMAL;
      default:
        // Try case-insensitive substring checks
        final upper = value.toUpperCase();
        if (upper.contains('GOOD')) return InventoryBatchStatus.GOOD;
        if (upper.contains('OUT_OF_STOCK') || upper.contains('OUT OF STOCK')) return InventoryBatchStatus.OUT_OF_STOCK;
        if (upper.contains('EXPIRING_SOON') || upper.contains('EXPIRING SOON')) return InventoryBatchStatus.EXPIRING_SOON;
        if (upper.contains('LOW_STOCK') || upper.contains('LOW STOCK')) return InventoryBatchStatus.LOW_STOCK;
        if (upper.contains('NORMAL')) return InventoryBatchStatus.NORMAL;
        throw ArgumentError('Invalid status: $value');
    }
  }
}
