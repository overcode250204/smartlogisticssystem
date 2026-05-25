import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.inventory(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'expired') {
      return StatusChip(label: status, color: const Color(0xFFDC2626));
    }
    if (normalized == 'low stock') {
      return StatusChip(label: status, color: const Color(0xFFF97316));
    }
    return StatusChip(label: status, color: const Color(0xFF16A34A));
  }

  factory StatusChip.transaction(String type) {
    final normalized = type.toUpperCase();
    return StatusChip(
      label: normalized,
      color: normalized == 'EXPORT'
          ? const Color(0xFFDC2626)
          : const Color(0xFF16A34A),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
