import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';

class TripPreAcceptView extends StatelessWidget {
  final LocalTripResponse trip;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const TripPreAcceptView({
    super.key,
    required this.trip,
    required this.isBusy,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDetails = [...trip.details]
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.localTripCode,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _infoRow(Icons.warehouse, 'Kho xuất phát', trip.hub?.name ?? '—'),
                _infoRow(
                  Icons.local_shipping,
                  'Xe',
                  trip.vehicle?.licensePlate ?? '—',
                ),
                _infoRow(
                  Icons.route,
                  'Số điểm giao',
                  '${trip.details.length} điểm',
                ),
                if (trip.vrpEstimatedMinutes != null)
                  _infoRow(
                    Icons.timer,
                    'Thời gian dự kiến',
                    '${trip.vrpEstimatedMinutes} phút',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Danh sách điểm giao',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...sortedDetails.map(
          (detail) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${detail.stopOrder}')),
              title: Text(detail.order.customerName),
              subtitle: Text(detail.order.deliveryAddress),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onCancel,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Từ chối'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isBusy ? null : onAccept,
                child: isBusy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Nhận chuyến'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
