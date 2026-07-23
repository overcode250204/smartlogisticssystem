class FailPointRequest {
  final int reasonId;
  final String? notes;

  const FailPointRequest({required this.reasonId, this.notes});

  Map<String, dynamic> toJson() {
    return {
      'reasonId': reasonId,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    };
  }
}
