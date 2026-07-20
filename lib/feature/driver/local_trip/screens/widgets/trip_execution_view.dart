import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/fail_point_request_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_response_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_status.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/customer_info_card.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/fail_point_sheet.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/capture_photo.dart';

class TripExecutionView extends StatefulWidget {
  final LocalTripResponse trip;
  final Future<void> Function(LocalTripDetailResponse detail) onArrive;
  final Future<void> Function(LocalTripDetailResponse detail, XFile proofImage) onComplete;
  final Future<void> Function(
    LocalTripDetailResponse detail,
    XFile proofImage,
    FailPointRequest data,
  ) onFail;

  const TripExecutionView({
    super.key,
    required this.trip,
    required this.onArrive,
    required this.onComplete,
    required this.onFail,
  });

  @override
  State<TripExecutionView> createState() => _TripExecutionViewState();
}

class _TripExecutionViewState extends State<TripExecutionView> {
  int? _busyDetailId;

  Future<void> _run(int detailId, Future<void> Function() action) async {
    setState(() => _busyDetailId = detailId);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busyDetailId = null);
    }
  }

  Future<void> _handleComplete(LocalTripDetailResponse detail) async {
    final photo = await captureProofPhoto(context);
    if (photo == null || !mounted) return;
    await _run(detail.id, () => widget.onComplete(detail, photo));
  }

  Future<void> _handleFail(LocalTripDetailResponse detail) async {
    final reason = await showFailPointSheet(context);
    if (reason == null || !mounted) return;
    final photo = await captureProofPhoto(context);
    if (photo == null || !mounted) return;
    await _run(detail.id, () => widget.onFail(detail, photo, reason));
  }

  @override
  Widget build(BuildContext context) {
    final sortedDetails = [...widget.trip.details]
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    final nextActiveIndex = sortedDetails.indexWhere(
      (d) =>
          d.status == LocalTripDetailStatus.PENDING ||
          d.status == LocalTripDetailStatus.ARRIVED,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDetails.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final detail = sortedDetails[index];
        final isActive = index == nextActiveIndex;
        final isBusy = _busyDetailId == detail.id;

        return Opacity(
          opacity: isActive || _isDone(detail) ? 1 : 0.45,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text('${detail.stopOrder}')),
                      const SizedBox(width: 8),
                      Expanded(child: CustomerInfoCard(order: detail.order)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAction(detail, isActive, isBusy),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isDone(LocalTripDetailResponse detail) =>
      detail.status == LocalTripDetailStatus.COMPLETED ||
      detail.status == LocalTripDetailStatus.FAILED;

  Widget _buildAction(LocalTripDetailResponse detail, bool isActive, bool isBusy) {
    if (_isDone(detail)) {
      return Row(
        children: [
          Icon(
            detail.status == LocalTripDetailStatus.COMPLETED
                ? Icons.check_circle
                : Icons.cancel,
            color: detail.status.color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            detail.status.label,
            style: TextStyle(color: detail.status.color, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (detail.proofUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                detail.proofUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
        ],
      );
    }

    if (!isActive) {
      return Text(
        detail.status.label,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    if (isBusy) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (detail.status == LocalTripDetailStatus.PENDING) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _run(detail.id, () => widget.onArrive(detail)),
          icon: const Icon(Icons.pin_drop),
          label: const Text('Đã đến nơi'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleFail(detail),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Thất bại'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => _handleComplete(detail),
            child: const Text('Hoàn thành'),
          ),
        ),
      ],
    );
  }
}
