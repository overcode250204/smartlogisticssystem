import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/zone_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/zone/service/zone_service.dart';
import 'package:smartlogisticssystem/feature/zone/screens/zone_draw_dialog.dart';

class ZoneManagementPage extends StatefulWidget {
  const ZoneManagementPage({super.key});

  @override
  State<ZoneManagementPage> createState() => _ZoneManagementPageState();
}

class _ZoneManagementPageState extends State<ZoneManagementPage> {
  final ZoneService _zoneService = ZoneService();
  List<ZoneModel> _zones = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _zoneService.getAllZones();
      if (mounted) {
        setState(() {
          _zones = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = apiErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteZone(ZoneModel zone) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khu vực "${zone.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _zoneService.deleteZone(zone.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa khu vực thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${apiErrorMessage(e)}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showZoneDialog([ZoneModel? zone]) {
    showDialog<ZoneCreateRequest?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ZoneDrawDialog(zone: zone),
    ).then((request) async {
      if (request != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          if (zone == null) {
            await _zoneService.createZone(request);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tạo khu vực thành công'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } else {
            await _zoneService.updateZone(zone.id, request);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cập nhật khu vực thành công'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
          _loadData();
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${apiErrorMessage(e)}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    });
  }

  int _getVerticesCount(ZoneModel zone) {
    try {
      final coverage = zone.coverageArea;
      if (coverage['type'] == 'Polygon' && coverage['coordinates'] is List) {
        final List rings = coverage['coordinates'];
        if (rings.isNotEmpty && rings[0] is List) {
          // If closed polygon, coordinates has N points (last one matches first). So vertices is N - 1
          final count = (rings[0] as List).length;
          return count > 1 ? count - 1 : count;
        }
      }
    } catch (_) {}
    return 0;
  }

  LatLng _getPolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(10.762622, 106.660172);
    double sumLat = 0;
    double sumLng = 0;
    for (var p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  List<Polygon> _getPolygons() {
    final List<Polygon> list = [];
    final colors = [
      AppColors.primary.withValues(alpha: 0.25),
      AppColors.success.withValues(alpha: 0.25),
      AppColors.warning.withValues(alpha: 0.25),
      AppColors.info.withValues(alpha: 0.25),
    ];
    final borderColors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];

    for (int i = 0; i < _zones.length; i++) {
      final zone = _zones[i];
      final coverage = zone.coverageArea;
      if (coverage['type'] == 'Polygon' && coverage['coordinates'] is List) {
        try {
          final List rings = coverage['coordinates'];
          if (rings.isNotEmpty && rings[0] is List) {
            final List ring = rings[0];
            final List<LatLng> points = [];
            for (var coord in ring) {
              if (coord is List && coord.length >= 2) {
                final double lng = (coord[0] as num).toDouble();
                final double lat = (coord[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
            if (points.isNotEmpty) {
              list.add(
                Polygon(
                  points: points,
                  color: colors[i % colors.length],
                  borderColor: borderColors[i % borderColors.length],
                  borderStrokeWidth: 3,
                  isFilled: true,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error parsing polygon: $e');
        }
      }
    }
    return list;
  }

  List<Marker> _getCenterMarkers() {
    final List<Marker> markers = [];
    for (int i = 0; i < _zones.length; i++) {
      final zone = _zones[i];
      final coverage = zone.coverageArea;
      if (coverage['type'] == 'Polygon' && coverage['coordinates'] is List) {
        try {
          final List rings = coverage['coordinates'];
          if (rings.isNotEmpty && rings[0] is List) {
            final List ring = rings[0];
            final List<LatLng> points = [];
            for (var coord in ring) {
              if (coord is List && coord.length >= 2) {
                final double lng = (coord[0] as num).toDouble();
                final double lat = (coord[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
            if (points.isNotEmpty) {
              final center = _getPolygonCenter(points);
              markers.add(
                Marker(
                  point: center,
                  width: 120,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        zone.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        } catch (_) {}
      }
    }
    return markers;
  }

  LatLng _getInitialMapCenter() {
    final polygons = _getPolygons();
    if (polygons.isNotEmpty && polygons.first.points.isNotEmpty) {
      return _getPolygonCenter(polygons.first.points);
    }
    return const LatLng(10.762622, 106.660172); // Default to HCMC
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _zones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final polygons = _getPolygons();

    return PageScroll(
      child: Column(
        children: [
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Quản lý Khu vực (Zones)')),
                    ElevatedButton.icon(
                      onPressed: () => _showZoneDialog(),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Thêm khu vực'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_zones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Chưa có khu vực nào được cấu hình',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  DarkTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Tên khu vực')),
                      DataColumn(label: Text('Số điểm mốc')),
                      DataColumn(label: Text('SLA (giờ)')),
                      DataColumn(label: Text('Ngày tạo')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: _zones
                        .map(
                          (zone) => DataRow(
                            cells: [
                              DataCell(Text(zone.id.toString())),
                              DataCell(Text(zone.name)),
                              DataCell(Text('${_getVerticesCount(zone)} điểm')),
                              DataCell(Text(zone.slaHours != null ? '${zone.slaHours}h' : 'Không có')),
                              DataCell(
                                Text(
                                  zone.createAt != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(zone.createAt!)
                                      : 'Không xác định',
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showZoneDialog(zone),
                                      icon: const Icon(Icons.edit_location_alt_outlined),
                                      color: AppColors.primary,
                                      tooltip: 'Chỉnh sửa vùng vẽ',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteZone(zone),
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppColors.danger,
                                      tooltip: 'Xóa khu vực',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          if (_zones.isNotEmpty) ...[
            const SizedBox(height: 20),
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Bản đồ trực quan hóa khu vực'),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _getInitialMapCenter(),
                          initialZoom: 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                          ),
                          PolygonLayer(
                            polygons: polygons,
                          ),
                          MarkerLayer(
                            markers: _getCenterMarkers(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
