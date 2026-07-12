import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';

class CollapseLocalTripDialog extends StatefulWidget {
  final LocalTripModel trip;
  final List<LocalTripModel> localTrips;
  final Future<void> Function(int targetTripId) onCollapse;

  const CollapseLocalTripDialog({
    super.key,
    required this.trip,
    required this.localTrips,
    required this.onCollapse,
  });

  @override
  State<CollapseLocalTripDialog> createState() => _CollapseLocalTripDialogState();
}

class _CollapseLocalTripDialogState extends State<CollapseLocalTripDialog> {
  int? _selectedTargetTripId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final validTargets = widget.localTrips.where((t) {
      if (t.localTripId == widget.trip.localTripId) return false;
      if (t.status == LocalTripStatus.CANCELLED || t.status == LocalTripStatus.COMPLETED) return false;
      return true;
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Gộp chuyến Last-Mile #${widget.trip.localTripCode ?? widget.trip.localTripId}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn chuyến đi đích để gộp đơn hàng từ chuyến hiện tại sang:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (validTargets.isEmpty)
              const Text(
                'Không tìm thấy chuyến đi hợp lệ nào để gộp.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedTargetTripId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn chuyến đích'),
                items: validTargets.map((t) {
                  return DropdownMenuItem<int>(
                    value: t.localTripId,
                    child: Text('${t.localTripCode ?? "LM-${t.localTripId}"} (${t.details?.length ?? 0} đơn)'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTargetTripId = val;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSubmitting || _selectedTargetTripId == null
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                  });
                  try {
                    await widget.onCollapse(_selectedTargetTripId!);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Gộp', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
