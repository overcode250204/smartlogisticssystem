class InvoiceCreateRequest {
  final String invoiceType;
  final double totalAmount;
  final int createdById;

  const InvoiceCreateRequest({
    required this.invoiceType,
    required this.totalAmount,
    required this.createdById,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceType': invoiceType,
      'totalAmount': totalAmount,
      'createdById': createdById,
    };
  }
}

class InvoiceUpdateRequest {
  final String invoiceType;
  final double totalAmount;
  final int createdById;

  const InvoiceUpdateRequest({
    required this.invoiceType,
    required this.totalAmount,
    required this.createdById,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceType': invoiceType,
      'totalAmount': totalAmount,
      'createdById': createdById,
    };
  }
}
