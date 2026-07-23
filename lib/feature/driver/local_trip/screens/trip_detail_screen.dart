import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/fail_point_request_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_response_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_status.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/trip_execution_view.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/trip_pre_accept_view.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/trip_scan_view.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/screens/widgets/trip_summary_view.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/services/local_trip_driver_service.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/driver_id_resolver.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/local_trip_error.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/location_helper.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  final LocalTripResponse? initialTrip;

  const TripDetailScreen({super.key, required this.tripId, this.initialTrip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final LocalTripDriverService _service = LocalTripDriverService();

  int? _driverId;
  LocalTripResponse? _trip;
  bool _isLoading = true;
  bool _isActionBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trip = widget.initialTrip;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _driverId = await resolveDriverId();
      await _refresh();
    } catch (e) {
      setState(() {
        _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_driverId == null) return;
    setState(() {
      _isLoading = _trip == null;
      _errorMessage = null;
    });
    try {
      final trips = await _service.getMyTrips(_driverId!);
      final trip = trips.where((t) => t.localTripId == widget.tripId).firstOrNull;
      if (trip == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy chuyến đi';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = localTripErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localTripErrorMessage(error)), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isActionBusy = true);
    try {
      await action();
      await _refresh();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _handleAccept() =>
      _runAction(() => _service.acceptTrip(_driverId!, widget.tripId));

  Future<void> _handleCancel() =>
      _runAction(() => _service.cancelTrip(_driverId!, widget.tripId));

  Future<void> _handleScan(int detailId, int orderId, String barcode) =>
      _runAction(() => _service.scanBarcode(_driverId!, widget.tripId, orderId, barcode));

  Future<void> _handleStartExecuting() =>
      _runAction(() => _service.startExecuting(_driverId!, widget.tripId));

  Future<void> _handleArrive(LocalTripDetailResponse detail) => _runAction(() async {
    final position = await getCurrentHighAccuracyPosition();
    await _service.arrive(
      _driverId!,
      widget.tripId,
      detail.id,
      position.latitude,
      position.longitude,
    );
  });

  Future<void> _handleComplete(LocalTripDetailResponse detail, XFile proofImage) =>
      _runAction(() => _service.completePoint(_driverId!, widget.tripId, detail.id, proofImage));

  Future<void> _handleFail(
    LocalTripDetailResponse detail,
    XFile proofImage,
    FailPointRequest data,
  ) => _runAction(
    () => _service.failPoint(_driverId!, widget.tripId, detail.id, proofImage, data),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip?.localTripCode ?? 'Chuyến đi'),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _trip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }

    final trip = _trip!;
    switch (trip.status) {
      case LocalTripStatus.PENDING_ACCEPTANCE:
        return TripPreAcceptView(
          trip: trip,
          isBusy: _isActionBusy,
          onAccept: _handleAccept,
          onCancel: _handleCancel,
        );
      case LocalTripStatus.ACCEPTED:
        return TripScanView(
          trip: trip,
          onScan: _handleScan,
          onStartExecuting: _handleStartExecuting,
          isBusy: _isActionBusy,
        );
      case LocalTripStatus.EXECUTING:
        return TripExecutionView(
          trip: trip,
          onArrive: _handleArrive,
          onComplete: _handleComplete,
          onFail: _handleFail,
        );
      case LocalTripStatus.COMPLETED:
        return TripSummaryView(trip: trip);
      case LocalTripStatus.CANCELLED:
        return const Center(child: Text('Chuyến đi đã bị huỷ'));
      case LocalTripStatus.ASSIGNED:
        return const Center(child: Text('Đang chờ điều phối lại chuyến đi'));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
