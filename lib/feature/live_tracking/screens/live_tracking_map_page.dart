import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/feature/live_tracking/services/live_tracking_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class LiveTrackingMapPage extends StatefulWidget {
  const LiveTrackingMapPage({super.key});

  @override
  State<LiveTrackingMapPage> createState() => _LiveTrackingMapPageState();
}

class _LiveTrackingMapPageState extends State<LiveTrackingMapPage> {
  final LiveTrackingService _trackingService = LiveTrackingService();
  final MapController _mapController = MapController();
  
  List<ActiveVehicleInfo> _activeVehicles = [];
  ActiveVehicleInfo? _selectedVehicle;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _trackingService.fetchActiveVehicles();
      setState(() {
        _activeVehicles = vehicles;
        _isLoading = false;
      });

      // Connect to WebSocket room for real-time updates
      _trackingService.connectAdminRoom(
        onUpdate: (updatedVehicle) {
          if (!mounted) return;
          setState(() {
            final index = _activeVehicles.indexWhere((v) => v.tripCode == updatedVehicle.tripCode);
            if (index >= 0) {
              _activeVehicles[index] = updatedVehicle;
            } else {
              _activeVehicles.add(updatedVehicle);
            }

            if (_selectedVehicle?.tripCode == updatedVehicle.tripCode) {
              _selectedVehicle = updatedVehicle;
              if (updatedVehicle.lat != null && updatedVehicle.lng != null) {
                _mapController.move(
                  LatLng(updatedVehicle.lat!, updatedVehicle.lng!),
                  _mapController.camera.zoom,
                );
              }
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối dịch vụ live tracking: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return AppColors.success;
      case 'yellow':
        return AppColors.warning;
      case 'gray':
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return 'Đúng hạn (SLA)';
      case 'yellow':
        return 'Trễ hạn / Cảnh báo';
      case 'gray':
      default:
        return 'Chưa có tọa độ';
    }
  }

  @override
  void dispose() {
    _trackingService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel: List of active vehicles
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.radar, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Giám sát hành trình live',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _trackingService.isConnected ? AppColors.success : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _trackingService.isConnected ? 'Live' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _trackingService.isConnected ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                              ),
                            )
                          : _activeVehicles.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Không có chuyến đi linehaul nào đang chạy.',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _activeVehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = _activeVehicles[index];
                                    final isSelected = _selectedVehicle?.tripCode == vehicle.tripCode;
                                    return ListTile(
                                      selected: isSelected,
                                      selectedTileColor: AppColors.primary.withOpacity(0.08),
                                      leading: CircleAvatar(
                                        backgroundColor: _getStatusColor(vehicle.status).withOpacity(0.2),
                                        child: Icon(
                                          Icons.local_shipping,
                                          color: _getStatusColor(vehicle.status),
                                        ),
                                      ),
                                      title: Text(
                                        vehicle.tripCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tài xế: ${vehicle.shipperName}'),
                                          Text('Hạn cuối: ${vehicle.deadline}'),
                                          if (vehicle.lastPingTime != null)
                                            Text(
                                              'Ping cuối: ${vehicle.lastPingTime}',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                            ),
                                        ],
                                      ),
                                      trailing: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getStatusColor(vehicle.status),
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedVehicle = vehicle;
                                        });
                                        if (vehicle.lat != null && vehicle.lng != null) {
                                          _mapController.move(
                                            LatLng(vehicle.lat!, vehicle.lng!),
                                            13.0,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          // Right panel: Map view
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.762, 106.660),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                    ),
                    MarkerLayer(
                      markers: _activeVehicles
                          .where((v) => v.lat != null && v.lng != null)
                          .map((vehicle) {
                        final point = LatLng(vehicle.lat!, vehicle.lng!);
                        final isSelected = _selectedVehicle?.tripCode == vehicle.tripCode;
                        return Marker(
                          point: point,
                          width: isSelected ? 60 : 45,
                          height: isSelected ? 60 : 45,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVehicle = vehicle;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(vehicle.status).withOpacity(0.4),
                                    blurRadius: isSelected ? 12 : 6,
                                    spreadRadius: isSelected ? 4 : 1,
                                  )
                                ],
                                border: Border.all(
                                  color: _getStatusColor(vehicle.status),
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: Icon(
                                Icons.local_shipping,
                                color: _getStatusColor(vehicle.status),
                                size: isSelected ? 30 : 22,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Selected Vehicle Detail Overlay Card
                if (_selectedVehicle != null)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: SafeArea(
                      child: DashboardCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _getStatusColor(_selectedVehicle!.status).withOpacity(0.2),
                              child: Icon(
                                Icons.local_shipping,
                                color: _getStatusColor(_selectedVehicle!.status),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _selectedVehicle!.tripCode,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_selectedVehicle!.status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getStatusLabel(_selectedVehicle!.status),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(_selectedVehicle!.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tài xế: ${_selectedVehicle!.shipperName}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Hạn định SLA: ${_selectedVehicle!.deadline}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  if (_selectedVehicle!.lastPingTime != null)
                                    Text(
                                      'Ping cuối: ${_selectedVehicle!.lastPingTime}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedVehicle = null;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
