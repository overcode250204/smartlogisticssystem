import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';

class CreatePalletDialog extends StatefulWidget {
  final List<RouteConfigModel> allRouteConfigs;
  final Future<void> Function(Map<String, dynamic> createData) onCreate;

  const CreatePalletDialog({
    super.key,
    required this.allRouteConfigs,
    required this.onCreate,
  });

  @override
  State<CreatePalletDialog> createState() => _CreatePalletDialogState();
}

class _CreatePalletDialogState extends State<CreatePalletDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedRouteId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Tạo Pallet mới',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn Tuyến đường *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: widget.allRouteConfigs.any((r) => r.routeId == _selectedRouteId)
                  ? _selectedRouteId
                  : null,
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
                });
              },
            ),
          ],
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
                      await widget.onCreate({
                        "routeConfigId": _selectedRouteId,
                      });
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
