import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_response_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_status.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/services/local_trip_driver_service.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/driver_id_resolver.dart';
import 'package:smartlogisticssystem/feature/driver/local_trip/utils/local_trip_error.dart';
import 'package:smartlogisticssystem/widgets/status_chip.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final LocalTripDriverService _service = LocalTripDriverService();

  int? _driverId;
  List<LocalTripResponse> _trips = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _driverId ??= await resolveDriverId();
      final trips = await _service.getMyTrips(_driverId!);
      trips.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e is Exception && e.toString().startsWith('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : localTripErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn giao hàng nội thành'),
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
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Chưa có chuyến đi nào được gán')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return Card(
            child: ListTile(
              title: Text(
                trip.localTripCode,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${trip.hub?.name ?? '—'} • ${trip.details.length} điểm giao',
              ),
              trailing: StatusChip(label: trip.status.label, color: trip.status.color),
              onTap: () => context.push(
                '/driver/local-trips/${trip.localTripId}',
                extra: trip,
              ).then((_) => _load()),
            ),
          );
        },
      ),
    );
  }
}
