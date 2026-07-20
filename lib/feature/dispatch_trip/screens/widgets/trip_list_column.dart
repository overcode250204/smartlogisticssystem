import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';

class TripListColumn extends StatelessWidget {
  final bool isLinehaulSelected;
  final List<LinehaulTripModel> linehaulTrips;
  final List<LocalTripModel> localTrips;
  final dynamic selectedTrip;
  final bool isLoadingTrips;
  final ValueChanged<dynamic> onSelectTrip;
  final ValueChanged<bool> onToggleLinehaul;
  final VoidCallback onCreateTrip;

  const TripListColumn({
    super.key,
    required this.isLinehaulSelected,
    required this.linehaulTrips,
    required this.localTrips,
    required this.selectedTrip,
    required this.isLoadingTrips,
    required this.onSelectTrip,
    required this.onToggleLinehaul,
    required this.onCreateTrip,
  });

  Color _getLinehaulStatusColor(LinehaulTripStatus? status) {
    switch (status) {
      case LinehaulTripStatus.PREPARING:
        return Colors.orange;
      case LinehaulTripStatus.EN_ROUTE:
        return Colors.blue;
      case LinehaulTripStatus.ARRIVED:
        return Colors.green;
      case LinehaulTripStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLocalStatusColor(LocalTripStatus? status) {
    switch (status) {
      case LocalTripStatus.PENDING_ACCEPTANCE:
        return Colors.orange;
      case LocalTripStatus.ACCEPTED:
        return Colors.blue;
      case LocalTripStatus.CANCELLED:
        return Colors.red;
      case LocalTripStatus.ASSIGNED:
        return Colors.indigo;
      case LocalTripStatus.EXECUTING:
        return Colors.amber;
      case LocalTripStatus.COMPLETED:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách Chuyến đi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: onCreateTrip,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                tooltip: 'Tạo Chuyến đi',
              ),
            ],
          ),
        ),
        // Toggle Linehaul / Last-Mile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggleLinehaul(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isLinehaulSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isLinehaulSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 16, color: isLinehaulSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Linehaul',
                            style: TextStyle(
                              color: isLinehaulSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isLinehaulSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggleLinehaul(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isLinehaulSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !isLinehaulSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.electric_moped_outlined,
                              size: 16, color: !isLinehaulSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Last-Mile',
                            style: TextStyle(
                              color: !isLinehaulSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: !isLinehaulSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: 'Tất cả Trạng thái',
                      items: ['Tất cả Trạng thái', 'Đang chuẩn bị', 'Sẵn sàng'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: 'Tất cả Ca',
                      items: ['Tất cả Ca', 'Ca 1', 'Ca 2'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm mã chuyến, tuyến đường...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: isLinehaulSelected ? linehaulTrips.length : localTrips.length,
                  itemBuilder: (context, index) {
                    if (isLinehaulSelected) {
                      return _buildLinehaulCard(linehaulTrips[index]);
                    } else {
                      return _buildLocalCard(localTrips[index]);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLinehaulCard(LinehaulTripModel trip) {
    final isSelected = selectedTrip == trip;
    double currentWeight = 0;
    for (var p in trip.pallets ?? []) {
      currentWeight += p.totalWeightKg ?? 0;
    }
    double maxWeight = (trip.vehicle ?? trip.routeConfig?.defaultVehicle)?.maxWeightKg ?? 500.0;
    if (maxWeight == 0) maxWeight = 500.0;
    double progress = (currentWeight / maxWeight).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => onSelectTrip(trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trip.linehaultripCode ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLinehaulStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip.status?.displayName ?? 'N/A',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getLinehaulStatusColor(trip.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.routeConfig?.routeName ?? 'N/A',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentWeight.toStringAsFixed(0)} / ${maxWeight.toStringAsFixed(0)} kg (${(progress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? Colors.red : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalCard(LocalTripModel trip) {
    final isSelected = selectedTrip == trip;

    final totalDetails = trip.details?.length ?? 0;
    final scannedDetails = trip.details?.where((d) => d.barcodeScanned == true).length ?? 0;
    final progress = totalDetails > 0 ? scannedDetails / totalDetails : 0.0;

    return GestureDetector(
      onTap: () => onSelectTrip(trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trip.localTripCode ?? 'LM-${trip.localTripId ?? "000"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLocalStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip.status?.displayName ?? 'N/A',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getLocalStatusColor(trip.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.hub?.name ?? 'N/A',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã quét: $scannedDetails / $totalDetails (${(progress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
