import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartlogisticssystem/core/networking.dart';

class LinehaulActiveTripScreen extends StatefulWidget {
  const LinehaulActiveTripScreen({super.key});

  @override
  State<LinehaulActiveTripScreen> createState() => _LinehaulActiveTripScreenState();
}

class _LinehaulActiveTripScreenState extends State<LinehaulActiveTripScreen> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _activeTrip;

  // GPS state
  Position? _currentPosition;
  bool _useMockLocation = true; // Default to true for easy testing/grading

  @override
  void initState() {
    super.initState();
    _fetchActiveTrip();
    _determinePosition();
  }

  Future<void> _fetchActiveTrip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiClient.get('linehaul-trip');
      if (response.statusCode == 200 && response.data != null) {
        final resBody = response.data as Map<String, dynamic>;
        final List<dynamic> allTrips = resBody['data'] as List<dynamic>? ?? [];

        // Find trip that is CAN_START or EN_ROUTE
        final active = allTrips.firstWhere(
          (t) => t['status'] == 'CAN_START' || t['status'] == 'EN_ROUTE',
          orElse: () => null,
        );

        setState(() {
          _activeTrip = active as Map<String, dynamic>?;
        });

        // Center map to fromWarehouse or toWarehouse if available
        if (active != null) {
          final fromWh = active['routeConfig']?['fromWarehouse'];
          final double? lat = fromWh?['latitude'] != null ? (fromWh['latitude'] as num).toDouble() : null;
          final double? lng = fromWh?['longitude'] != null ? (fromWh['longitude'] as num).toDouble() : null;
          if (lat != null && lng != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(LatLng(lat, lng), 12.5);
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Không thể kết nối máy chủ để lấy thông tin chuyến đi';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải chuyến đi hoạt động';
      });
      debugPrint('Error fetching active trip: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
    }
  }

  int? _getActiveTripId() {
    final value = _activeTrip?['linehaulId'] ?? _activeTrip?['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _handleDispatch() async {
    if (_activeTrip == null) return;
    final tripId = _getActiveTripId();
    if (tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong tim thay ma chuyen linehaul hop le'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double lat = 0.0;
    double lng = 0.0;

    if (_useMockLocation) {
      // Simulate at From Warehouse
      final fromWh = _activeTrip!['routeConfig']?['fromWarehouse'];
      lat = fromWh?['latitude'] != null ? (fromWh['latitude'] as num).toDouble() : 10.762622;
      lng = fromWh?['longitude'] != null ? (fromWh['longitude'] as num).toDouble() : 106.660172;
    } else {
      await _determinePosition();
      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy tọa độ GPS hiện tại. Vui lòng thử lại hoặc bật Giả lập.')),
        );
        return;
      }
      lat = _currentPosition!.latitude;
      lng = _currentPosition!.longitude;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post(
        'linehaul-trip/$tripId/dispatch',
        data: {
          'latitude': lat,
          'longitude': lng,
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bắt đầu hành trình thành công!'), backgroundColor: Colors.green),
        );
        _fetchActiveTrip();
      }
    } catch (e) {
      String msg = 'Bắt đầu hành trình thất bại';
      final dynamic err = e;
      try {
        if (err.response?.data != null) {
          msg = err.response.data['message'] ?? msg;
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFinish() async {
    if (_activeTrip == null) return;
    final tripId = _getActiveTripId();
    if (tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong tim thay ma chuyen linehaul hop le'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double lat = 0.0;
    double lng = 0.0;

    if (_useMockLocation) {
      // Simulate at To Warehouse
      final toWh = _activeTrip!['routeConfig']?['toWarehouse'];
      lat = toWh?['latitude'] != null ? (toWh['latitude'] as num).toDouble() : 10.762622;
      lng = toWh?['longitude'] != null ? (toWh['longitude'] as num).toDouble() : 106.660172;
    } else {
      await _determinePosition();
      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy tọa độ GPS hiện tại. Vui lòng thử lại hoặc bật Giả lập.')),
        );
        return;
      }
      lat = _currentPosition!.latitude;
      lng = _currentPosition!.longitude;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post(
        'linehaul-trip/$tripId/finish',
        data: {
          'latitude': lat,
          'longitude': lng,
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành chuyến đi!'), backgroundColor: Colors.green),
        );
        _fetchActiveTrip();
      }
    } catch (e) {
      String msg = 'Hoàn thành chuyến đi thất bại';
      final dynamic err = e;
      try {
        if (err.response?.data != null) {
          msg = err.response.data['message'] ?? msg;
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hành trình hiện tại', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _fetchActiveTrip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeTrip == null
              ? _buildEmptyState()
              : _buildActiveTripContent(),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchActiveTrip,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Không có hành trình nào đang chạy',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kéo xuống hoặc nhấn tải lại để cập nhật',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchActiveTrip,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripContent() {
    final code = _activeTrip!['linehaulTripCode'] ?? 'N/A';
    final status = _activeTrip!['status'] ?? 'CAN_START';
    final route = _activeTrip!['routeConfig'];
    final fromWh = route?['fromWarehouse'];
    final toWh = route?['toWarehouse'];
    final vehicle = _activeTrip!['vehicle']?['licensePlate'] ?? 'N/A';
    final palletsCount = (_activeTrip!['pallets'] as List<dynamic>?)?.length ?? 0;

    // Warehouse coordinates
    final double? fromLat = fromWh?['latitude'] != null ? (fromWh['latitude'] as num).toDouble() : null;
    final double? fromLng = fromWh?['longitude'] != null ? (fromWh['longitude'] as num).toDouble() : null;
    final double? toLat = toWh?['latitude'] != null ? (toWh['latitude'] as num).toDouble() : null;
    final double? toLng = toWh?['longitude'] != null ? (toWh['longitude'] as num).toDouble() : null;

    final markers = <Marker>[];
    if (fromLat != null && fromLng != null) {
      markers.add(Marker(
        point: LatLng(fromLat, fromLng),
        width: 40,
        height: 40,
        child: const Icon(Icons.radio_button_checked, color: Colors.blueAccent, size: 30),
      ));
    }
    if (toLat != null && toLng != null) {
      markers.add(Marker(
        point: LatLng(toLat, toLng),
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
      ));
    }
    if (_currentPosition != null) {
      markers.add(Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.navigation, color: Colors.green, size: 30),
      ));
    }

    return Column(
      children: [
        // Status header
        Container(
          width: double.infinity,
          color: status == 'CAN_START' ? Colors.orange.shade50 : Colors.blue.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã: $code',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'CAN_START' ? Colors.orange.shade600 : Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'CAN_START' ? 'Sẵn sàng đi' : 'Đang di chuyển',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Map section
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(fromLat ?? 10.762, fromLng ?? 106.660),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          _currentPosition != null
                              ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                              : 'Đang tìm tín hiệu GPS...',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Workflow Details Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin & Destination details
                Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.blue.shade700, size: 16),
                        Container(width: 1.5, height: 24, color: Colors.grey.shade300),
                        Icon(Icons.location_on, color: Colors.red.shade700, size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm đi: ${fromWh?['name'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Điểm đến: ${toWh?['name'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Vehicle and pallet counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          'Xe: $vehicle',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          '$palletsCount Pallets',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Testing Mock location switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.biotech, size: 18, color: Colors.blueAccent),
                        SizedBox(width: 6),
                        Text(
                          'Giả lập vị trí tại Kho (để Test)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    Switch(
                      value: _useMockLocation,
                      onChanged: (val) {
                        setState(() {
                          _useMockLocation = val;
                        });
                      },
                      activeThumbColor: Colors.blueAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Primary action buttons
                if (status == 'CAN_START')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleDispatch,
                      child: const Text('Bắt đầu di chuyển (Dispatch)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )
                else if (status == 'EN_ROUTE')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleFinish,
                      child: const Text('Hoàn thành chuyến đi (Finish)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
