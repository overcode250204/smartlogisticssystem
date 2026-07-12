import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/zone_model.dart';

class ZoneDrawDialog extends StatefulWidget {
  final ZoneModel? zone;

  const ZoneDrawDialog({super.key, this.zone});

  @override
  State<ZoneDrawDialog> createState() => _ZoneDrawDialogState();
}

class _ZoneDrawDialogState extends State<ZoneDrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slaController = TextEditingController();
  final List<LatLng> _points = [];
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  LatLng _center = const LatLng(10.762622, 106.660172); // Default to HCMC
  double _zoom = 13.0;

  @override
  void initState() {
    super.initState();
    if (widget.zone != null) {
      _nameController.text = widget.zone!.name;
      _slaController.text = widget.zone!.slaHours?.toString() ?? '';
      // Parse coordinates from geojson
      final coverage = widget.zone!.coverageArea;
      if (coverage['type'] == 'Polygon' && coverage['coordinates'] is List) {
        try {
          final List rings = coverage['coordinates'];
          if (rings.isNotEmpty && rings[0] is List) {
            final List ring = rings[0];
            for (var coord in ring) {
              if (coord is List && coord.length >= 2) {
                // GeoJSON uses [longitude, latitude]
                final double lng = (coord[0] as num).toDouble();
                final double lat = (coord[1] as num).toDouble();
                _points.add(LatLng(lat, lng));
              }
            }
            // GeoJSON Polygon closes with same start/end. We discard last point for UI drawing if closed
            if (_points.isNotEmpty &&
                _points.first.latitude == _points.last.latitude &&
                _points.first.longitude == _points.last.longitude) {
              _points.removeLast();
            }

            if (_points.isNotEmpty) {
              _center = _points.first;
            }
          }
        } catch (e) {
          debugPrint('Error parsing coverage area: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
    });
  }

  void _removeLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }

  void _clearPoints() {
    setState(() {
      _points.clear();
    });
  }

  Map<String, dynamic> _buildGeoJson() {
    // A GeoJSON Polygon needs at least 3 distinct points (4 points total with closure)
    final List<LatLng> closedPoints = List.from(_points);
    if (closedPoints.isNotEmpty) {
      closedPoints.add(closedPoints.first);
    }

    final List<List<double>> coords = closedPoints
        .map((latLng) => [latLng.longitude, latLng.latitude])
        .toList();

    return {
      'type': 'Polygon',
      'coordinates': [coords],
    };
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 3 điểm trên bản đồ để tạo vùng'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final int? slaHours = int.tryParse(_slaController.text.trim());
 
    final request = ZoneCreateRequest(
      name: _nameController.text.trim(),
      coverageArea: _buildGeoJson(),
      slaHours: slaHours,
    );
 
    Navigator.pop(context, request);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.card,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.zone == null ? 'Thêm khu vực mới' : 'Chỉnh sửa khu vực',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khu vực *',
                        hintText: 'Nhập tên khu vực',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Bắt buộc nhập tên khu vực'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _slaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'SLA (giờ)',
                        hintText: 'VD: 4',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final val = int.tryParse(value.trim());
                          if (val == null || val <= 0) {
                            return 'Phải là số nguyên dương';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _points.isEmpty ? null : _removeLastPoint,
                  icon: const Icon(Icons.undo),
                  label: const Text('Hoàn tác điểm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _points.isEmpty ? null : _clearPoints,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Xóa tất cả'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Nhấp chuột trên bản đồ để nối các điểm tạo thành vùng bao',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                  ),
                  child: FlutterMap(
                    key: _mapKey,
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _zoom,
                      onTap: (tapPosition, point) => _addPoint(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                      ),
                      if (_points.isNotEmpty) ...[
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: _points,
                              color: AppColors.primary.withValues(alpha: 0.3),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 3,
                              isFilled: true,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: _points.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final point = entry.value;
                            return Marker(
                              point: point,
                              width: 30,
                              height: 30,
                              child: Builder(
                                builder: (markerContext) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanUpdate: (details) {
                                      final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
                                      if (renderBox != null) {
                                        final localOffset = renderBox.globalToLocal(details.globalPosition);
                                        final camera = MapCamera.of(markerContext);
                                        final newLatLng = camera.pointToLatLng(math.Point(localOffset.dx, localOffset.dy));
                                        setState(() {
                                          _points[idx] = newLatLng;
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: idx == 0 ? Colors.green : AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy bỏ'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu khu vực'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
