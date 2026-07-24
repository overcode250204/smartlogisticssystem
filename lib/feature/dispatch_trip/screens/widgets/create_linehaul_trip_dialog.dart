import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';

class CreateLinehaulTripDialog extends StatefulWidget {
  final List<RouteConfigModel> allRouteConfigs;
  final List<VehicleModel> allVehicles;
  final List<DriverModel> allDrivers;
  final Future<void> Function(Map<String, dynamic> createData) onCreate;

  const CreateLinehaulTripDialog({
    super.key,
    required this.allRouteConfigs,
    required this.allVehicles,
    required this.allDrivers,
    required this.onCreate,
  });

  @override
  State<CreateLinehaulTripDialog> createState() => _CreateLinehaulTripDialogState();
}

class _CreateLinehaulTripDialogState extends State<CreateLinehaulTripDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedRouteId;
  int? _selectedVehicleId;
  int? _selectedMainDriverId;
  int? _selectedAssistantDriverId;
  bool _isSubmitting = false;

  // Chỉ giữ lại id nếu nó thực sự có trong danh sách item của dropdown,
  // nếu không DropdownButton sẽ assert khi build.
  int? _validRouteId(int? id) =>
      widget.allRouteConfigs.any((r) => r.routeId == id) ? id : null;

  int? _validVehicleId(int? id) =>
      widget.allVehicles.any((v) => v.vehicleId == id) ? id : null;

  int? _validDriverId(int? id) =>
      widget.allDrivers.any((d) => d.driverId == id) ? id : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Tạo Chuyến đi Linehaul mới',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn Tuyến đường *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _validRouteId(_selectedRouteId),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn tuyến đường'),
                items: widget.allRouteConfigs.map((r) {
                  return DropdownMenuItem<int>(
                    value: r.routeId,
                    child: Text(r.routeName),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn tuyến đường';
                  }
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    _selectedRouteId = val;
                    if (val != null) {
                      final selectedRoute = widget.allRouteConfigs.firstWhere((element) => element.routeId == val);
                      // Xe mặc định của tuyến có thể không nằm trong danh sách xe khả dụng
                      _selectedVehicleId = _validVehicleId(selectedRoute.defaultVehicle?.vehicleId) ?? _selectedVehicleId;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Chọn Phương tiện (Tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _validVehicleId(_selectedVehicleId),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn xe'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không chọn xe'),
                  ),
                  ...widget.allVehicles.map((v) {
                    return DropdownMenuItem<int>(
                      value: v.vehicleId,
                      child: Text('${v.licensePlate ?? "N/A"} (${v.maxWeightKg} kg)'),
                    );
                  })
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedVehicleId = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Chọn Tài xế chính (MAIN - Tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _validDriverId(_selectedMainDriverId),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn tài xế chính'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không chọn tài xế chính'),
                  ),
                  // Loại tài xế đã chọn làm phụ để không thể chọn trùng.
                  ...widget.allDrivers
                      .where((d) => d.driverId != _selectedAssistantDriverId)
                      .map((d) {
                        return DropdownMenuItem<int>(
                          value: d.driverId,
                          child: Text('${d.name ?? "N/A"} - ${d.phone ?? ""}'),
                        );
                      })
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedMainDriverId = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Chọn Tài xế phụ (ASSISTANT - Tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _validDriverId(_selectedAssistantDriverId),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Không có'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không có tài xế phụ'),
                  ),
                  // Loại tài xế đã chọn làm chính để không thể chọn trùng.
                  ...widget.allDrivers
                      .where((d) => d.driverId != _selectedMainDriverId)
                      .map((d) {
                        return DropdownMenuItem<int>(
                          value: d.driverId,
                          child: Text('${d.name ?? "N/A"} - ${d.phone ?? ""}'),
                        );
                      })
                ],
                validator: (value) {
                  if (value != null) {
                    if (_selectedMainDriverId == null) {
                      return 'Phải chọn tài xế chính trước khi chọn tài xế phụ';
                    }
                    if (value == _selectedMainDriverId) {
                      return 'Tài xế phụ không được trùng tài xế chính';
                    }
                  }
                  return null;
                },
                onChanged: (val) {
                  setState(() {
                    _selectedAssistantDriverId = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isSubmitting = true;
                    });
                    List<Map<String, dynamic>> driverRequests = [];
                    if (_selectedMainDriverId != null) {
                      driverRequests.add({
                        'driverId': _selectedMainDriverId,
                        'role': 'MAIN',
                      });
                    }
                    if (_selectedAssistantDriverId != null) {
                      driverRequests.add({
                        'driverId': _selectedAssistantDriverId,
                        'role': 'ASSISTANT',
                      });
                    }

                    Map<String, dynamic> createData = {
                      'routeId': _selectedRouteId,
                      'vehicleId': _selectedVehicleId,
                      'linehaulTripDriverCreateRequest': driverRequests,
                    };

                    try {
                      await widget.onCreate(createData);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Tạo', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
