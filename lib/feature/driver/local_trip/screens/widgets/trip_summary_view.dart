import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_status.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';

class TripSummaryView extends StatelessWidget {
  final LocalTripResponse trip;

  const TripSummaryView({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final completed = trip.details
        .where((d) => d.status == LocalTripDetailStatus.COMPLETED)
        .length;
    final failed = trip.details
        .where((d) => d.status == LocalTripDetailStatus.FAILED)
        .length;
    final sortedDetails = [...trip.details]
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile('Thành công', completed, AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(child: _summaryTile('Thất bại', failed, AppColors.danger)),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Chi tiết các điểm giao',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...sortedDetails.map(
          (detail) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                detail.status == LocalTripDetailStatus.COMPLETED
                    ? Icons.check_circle
                    : Icons.cancel,
                color: detail.status.color,
              ),
              title: Text(detail.order.customerName),
              subtitle: Text(detail.order.deliveryAddress),
              trailing: Text(
                detail.status.label,
                style: TextStyle(color: detail.status.color, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
