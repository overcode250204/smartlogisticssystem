import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/feature/warehouse/service/warehouse_service.dart';
import 'package:smartlogisticssystem/feature/vehicle/service/vehicle_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:dio/dio.dart';


class CreateRouteConfigDialog extends StatefulWidget {
  final RouteConfigModel? routeConfig;

  const CreateRouteConfigDialog({super.key, this.routeConfig});

  @override
  State<CreateRouteConfigDialog> createState() => _CreateRouteConfigDialogState();
}

class _CreateRouteConfigDialogState extends State<CreateRouteConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minCapacityController = TextEditingController();
  final _maxWaitingDaysController = TextEditingController();

  final WarehouseService _warehouseService = WarehouseService();
  final VehicleService _vehicleService = VehicleService();

  List<WarehouseModel> _warehouses = [];
  List<VehicleModel> _vehicles = [];
  List<String> _provinceOptions = [];
  List<String> _selectedProvinces = [];

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _selectedFromWarehouseId;
  int? _selectedToWarehouseId;
  int? _selectedVehicleId;
  DispatchType _selectedDispatchType = DispatchType.TIME;

  TimeOfDay? _fixedDispatchTime;
  TimeOfDay? _cutoffTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();

    if (widget.routeConfig != null) {
      final rc = widget.routeConfig!;
      _nameController.text = rc.routeName;
      _selectedFromWarehouseId = rc.fromWarehouse.warehouseId;
      _selectedToWarehouseId = rc.toWarehouse.warehouseId;
      _selectedVehicleId = rc.defaultVehicle?.vehicleId;
      _selectedDispatchType = rc.dispatchType;

      if (rc.minCapacityPercentage != null) {
        _minCapacityController.text = rc.minCapacityPercentage.toString();
      }
      if (rc.maxWaitingDays != null) {
        _maxWaitingDaysController.text = rc.maxWaitingDays.toString();
      }
      _selectedProvinces = List<String>.from(rc.provinceNames);

      if (rc.fixedDispatchTime != null) {
        _fixedDispatchTime = _parseTimeString(rc.fixedDispatchTime!);
      }
      _cutoffTime = _parseTimeString(rc.cutoffTime);
      _isActive = rc.isActive;
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _loadDropdownData() async {
    try {
      final warehouses = await _warehouseService.getAllWarehouses();
      final vehicles = await _vehicleService.getAllVehicles();
      
      final dio = Dio();
      final response = await dio.get('https://provinces.open-api.vn/api/v2/p/');
      List<String> provinces = [];
      if (response.statusCode == 200 && response.data is List) {
        provinces = (response.data as List)
            .map((p) => p['name'] as String)
            .toList();
      }

      if (mounted) {
        setState(() {
          _warehouses = warehouses;
          _vehicles = vehicles;
          _provinceOptions = provinces;
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu cấu hình hoặc danh sách tỉnh thành: ${apiErrorMessage(e)}';
          _isLoadingDropdowns = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minCapacityController.dispose();
    _maxWaitingDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isCutoff) async {
    final initialTime = isCutoff 
        ? (_cutoffTime ?? const TimeOfDay(hour: 17, minute: 0)) 
        : (_fixedDispatchTime ?? const TimeOfDay(hour: 12, minute: 0));
        
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCutoff) {
          _cutoffTime = picked;
        } else {
          _fixedDispatchTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFromWarehouseId == null || _selectedToWarehouseId == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn đầy đủ kho đi và kho đến';
      });
      return;
    }
    if (_selectedFromWarehouseId == _selectedToWarehouseId) {
      setState(() {
        _errorMessage = 'Kho đi và kho đến không được giống nhau';
      });
      return;
    }
    if (_cutoffTime == null) {
      setState(() {
        _errorMessage = 'Vui lòng cấu hình thời gian chốt chuyến (Cutoff time)';
      });
      return;
    }

    // Fixed Dispatch Time is required for TIME and HYBRID types
    if ((_selectedDispatchType == DispatchType.TIME || _selectedDispatchType == DispatchType.HYBRID) && 
        _fixedDispatchTime == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn thời gian xuất bến cố định';
      });
      return;
    }

    final fixedTimeStr = _fixedDispatchTime != null ? _formatTimeOfDay(_fixedDispatchTime!) : null;
    final cutoffTimeStr = _formatTimeOfDay(_cutoffTime!);
    final minCapacity = _minCapacityController.text.isNotEmpty ? int.tryParse(_minCapacityController.text) : null;
    final maxWaiting = _maxWaitingDaysController.text.isNotEmpty ? int.tryParse(_maxWaitingDaysController.text) : null;

    final result = {
      'routeName': _nameController.text.trim(),
      'fromWarehouseId': _selectedFromWarehouseId,
      'toWarehouseId': _selectedToWarehouseId,
      'dispatchType': _selectedDispatchType,
      'fixedDispatchTime': fixedTimeStr,
      'minCapacityPercentage': minCapacity,
      'cutoffTime': cutoffTimeStr,
      'maxWaitingDays': maxWaiting,
      'defaultVehicleId': _selectedVehicleId,
      'provinceNames': _selectedProvinces,
      'isActive': _isActive,
    };

    Navigator.pop(context, result);
  }

  void _showProvinceSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelected = List<String>.from(_selectedProvinces);
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredProvinces = _provinceOptions
                .where((province) => province.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Chọn tỉnh/thành phố đi qua'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm tỉnh/thành...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected = List<String>.from(_provinceOptions);
                            });
                          },
                          child: const Text('Chọn tất cả'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text('Bỏ chọn tất cả'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: filteredProvinces.isEmpty
                          ? const Center(child: Text('Không tìm thấy kết quả'))
                          : ListView.builder(
                              itemCount: filteredProvinces.length,
                              itemBuilder: (context, index) {
                                final province = filteredProvinces[index];
                                final isChecked = tempSelected.contains(province);
                                return CheckboxListTile(
                                  title: Text(province),
                                  value: isChecked,
                                  activeColor: AppColors.primary,
                                  onChanged: (bool? val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        tempSelected.add(province);
                                      } else {
                                        tempSelected.remove(province);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedProvinces = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDropdowns) {
      return const AlertDialog(
        backgroundColor: AppColors.card,
        content: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final isTimeBased = _selectedDispatchType == DispatchType.TIME;
    final isCapacityBased = _selectedDispatchType == DispatchType.CAPACITY;
    final isHybrid = _selectedDispatchType == DispatchType.HYBRID;

    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(widget.routeConfig == null ? 'Cấu hình tuyến đường mới' : 'Chỉnh sửa cấu hình tuyến đường'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tuyến đường *',
                    hintText: 'VD: Tuyến HN - HCM',
                    prefixIcon: Icon(Icons.alt_route),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty 
                      ? 'Vui lòng nhập tên tuyến đường' 
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedFromWarehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Kho khởi hành (Kho đi) *',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                  ),
                  items: _warehouses.map((wh) {
                    return DropdownMenuItem<int>(
                      value: wh.warehouseId,
                      child: Text(wh.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFromWarehouseId = val),
                  validator: (value) => value == null ? 'Vui lòng chọn kho khởi hành' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedToWarehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Kho đích (Kho đến) *',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                  ),
                  items: _warehouses.map((wh) {
                    return DropdownMenuItem<int>(
                      value: wh.warehouseId,
                      child: Text(wh.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedToWarehouseId = val),
                  validator: (value) => value == null ? 'Vui lòng chọn kho đích' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Phương tiện mặc định',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  items: _vehicles.map((v) {
                    return DropdownMenuItem<int>(
                      value: v.vehicleId,
                      child: Text('${v.licensePlate} (${v.vehicleType.displayName})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedVehicleId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DispatchType>(
                  value: _selectedDispatchType,
                  decoration: const InputDecoration(
                    labelText: 'Loại điều phối chuyến xe *',
                    prefixIcon: Icon(Icons.settings_outlined),
                  ),
                  items: DispatchType.values.map((type) {
                    return DropdownMenuItem<DispatchType>(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDispatchType = val;
                        // Reset parameters that aren't needed
                        if (val == DispatchType.TIME) {
                          _minCapacityController.clear();
                          _maxWaitingDaysController.clear();
                        } else if (val == DispatchType.CAPACITY) {
                          _fixedDispatchTime = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cấu hình lịch trình chuyến đi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Fixed dispatch time selector
                if (isTimeBased || isHybrid) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fixedDispatchTime == null 
                              ? 'Giờ xuất bến cố định: Chưa chọn *' 
                              : 'Giờ xuất bến cố định: ${_fixedDispatchTime!.format(context)}',
                          style: TextStyle(
                            color: _fixedDispatchTime == null ? AppColors.danger : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectTime(context, false),
                        icon: const Icon(Icons.access_time),
                        label: const Text('Chọn giờ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Cutoff time selector
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _cutoffTime == null 
                            ? 'Giờ chốt chuyến (Cutoff): Chưa chọn *' 
                            : 'Giờ chốt chuyến (Cutoff): ${_cutoffTime!.format(context)}',
                        style: TextStyle(
                          color: _cutoffTime == null ? AppColors.danger : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: const Icon(Icons.access_time),
                      label: const Text('Chọn giờ'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Capacity constraints
                if (isCapacityBased || isHybrid) ...[
                  TextFormField(
                    controller: _minCapacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tải trọng tối thiểu (%) *',
                      hintText: 'Nhập từ 1 đến 100',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập phần trăm tải trọng tối thiểu';
                      }
                      final pct = int.tryParse(value);
                      if (pct == null || pct < 1 || pct > 100) {
                        return 'Phần trăm tải trọng phải từ 1 đến 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxWaitingDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số ngày chờ tối đa',
                      hintText: 'Số ngày tối đa xe nằm bến chờ gom hàng',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final days = int.tryParse(value);
                        if (days == null || days < 1) {
                          return 'Số ngày chờ phải lớn hơn hoặc bằng 1';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                 const Text(
                  'Các tỉnh đi qua',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkest.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedProvinces.isEmpty)
                        const Text(
                          'Chưa chọn tỉnh thành nào',
                          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedProvinces.map((province) {
                            return Chip(
                              label: Text(province, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.border,
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _selectedProvinces.remove(province);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _showProvinceSelectionDialog,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Chọn tỉnh/thành phố'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Kích hoạt tuyến đường'),
                  subtitle: const Text('Cho phép tuyến đường này hoạt động điều phối'),
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu cấu hình'),
        ),
      ],
    );
  }
}
