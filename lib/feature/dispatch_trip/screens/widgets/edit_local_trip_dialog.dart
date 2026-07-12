import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';

class EditLocalTripDialog extends StatefulWidget {
  final LocalTripModel trip;
  final List<VehicleModel> allVehicles;
  final List<DriverModel> allDrivers;
  final Future<void> Function(int? vehicleId, int? driverId) onSave;

  const EditLocalTripDialog({
    super.key,
    required this.trip,
    required this.allVehicles,
    required this.allDrivers,
    required this.onSave,
  });

  @override
  State<EditLocalTripDialog> createState() => _EditLocalTripDialogState();
}

class _EditLocalTripDialogState extends State<EditLocalTripDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedVehicleId;
  int? _selectedDriverId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.trip.vehicle?.vehicleId;
    _selectedDriverId = widget.trip.driver?.driverId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Chỉnh sửa Chuyến Last-Mile #${widget.trip.localTripCode ?? widget.trip.localTripId}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn Phương tiện',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn xe'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không chọn xe / Bỏ chọn'),
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
              const Text('Chọn Tài xế',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _selectedDriverId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn tài xế'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Không chọn tài xế / Bỏ chọn'),
                  ),
                  ...widget.allDrivers.map((d) {
                    return DropdownMenuItem<int>(
                      value: d.driverId,
                      child: Text('${d.name ?? "N/A"} - ${d.phone ?? ""}'),
                    );
                  })
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedDriverId = val;
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
                    try {
                      await widget.onSave(_selectedVehicleId, _selectedDriverId);
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
              : const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
