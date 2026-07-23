import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/vehicle/service/vehicle_service.dart';
import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/feature/warehouse/service/warehouse_service.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({super.key});

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final VehicleService _vehicleService = VehicleService();
  List<VehicleModel> _allVehicles = [];
  List<VehicleModel> _filteredVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  VehicleType? _selectedTypeFilter;
  VehicleStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _vehicleService.getAllVehicles();
      if (mounted) {
        setState(() {
          _allVehicles = data;
          _isLoading = false;
        });
        _applyFilters();
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

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        final matchesSearch = vehicle.licensePlate.toLowerCase().contains(search);
        final matchesType = _selectedTypeFilter == null || vehicle.vehicleType == _selectedTypeFilter;
        final matchesStatus = _selectedStatusFilter == null || vehicle.status == _selectedStatusFilter;
        return matchesSearch && matchesType && matchesStatus;
      }).toList();
    });
  }

  Color _getStatusColor(VehicleStatus status) {
    return switch (status) {
      VehicleStatus.ACTIVE => AppColors.success,
      VehicleStatus.INACTIVE => AppColors.textSecondary,
      VehicleStatus.MAINTENANCE => AppColors.warning,
      VehicleStatus.ON_TRIP => AppColors.info,
    };
  }

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa phương tiện "${vehicle.licensePlate}" không?'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await _vehicleService.deleteVehicle(vehicle.vehicleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa phương tiện thành công'),
            backgroundColor: AppColors.success,
          ),
        );
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

  void _showVehicleDialog([VehicleModel? vehicle]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VehicleFormDialog(vehicle: vehicle, vehicleService: _vehicleService),
    ).then((success) {
      if (success == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle('Quản lý phương tiện')),
                ElevatedButton.icon(
                  onPressed: () => _showVehicleDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm phương tiện'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Search and Filters Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm theo biển số xe...',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<VehicleType>(
                    initialValue: _selectedTypeFilter,
                    hint: const Text('Loại phương tiện'),
                    items: [
                      const DropdownMenuItem<VehicleType>(
                        value: null,
                        child: Text('Tất cả loại'),
                      ),
                      ...VehicleType.values.map(
                        (type) => DropdownMenuItem<VehicleType>(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedTypeFilter = val;
                      });
                      _applyFilters();
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<VehicleStatus>(
                    initialValue: _selectedStatusFilter,
                    hint: const Text('Trạng thái'),
                    items: [
                      const DropdownMenuItem<VehicleStatus>(
                        value: null,
                        child: Text('Tất cả trạng thái'),
                      ),
                      ...VehicleStatus.values.map(
                        (status) => DropdownMenuItem<VehicleStatus>(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatusFilter = val;
                      });
                      _applyFilters();
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
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
              )
            else if (_filteredVehicles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Text(
                    'Không tìm thấy phương tiện nào',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ),
              )
            else
              DarkTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Biển số xe')),
                  DataColumn(label: Text('Loại phương tiện')),
                  DataColumn(label: Text('Tải trọng tối đa (kg)')),
                  DataColumn(label: Text('Thể tích tối đa (m³)')),
                  DataColumn(label: Text('Kho hiện tại')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _filteredVehicles
                    .map(
                      (vehicle) => DataRow(
                        cells: [
                          DataCell(Text(vehicle.vehicleId.toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                              ),
                              child: Text(
                                vehicle.licensePlate,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(vehicle.vehicleType.displayName)),
                          DataCell(Text(vehicle.maxWeightKg.toStringAsFixed(1))),
                          DataCell(Text(vehicle.maxVolumeM3.toStringAsFixed(2))),
                          DataCell(Text(vehicle.currentWarehouseName ?? 'Chưa gán')),
                          DataCell(
                            StatusPill(
                              label: vehicle.status.displayName,
                              color: _getStatusColor(vehicle.status),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showVehicleDialog(vehicle),
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteVehicle(vehicle),
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppColors.danger,
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
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  final VehicleModel? vehicle;
  final VehicleService vehicleService;

  const _VehicleFormDialog({this.vehicle, required this.vehicleService});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licensePlateController;
  late final TextEditingController _maxWeightController;
  late final TextEditingController _maxVolumeController;
  late VehicleType _vehicleType;
  late VehicleStatus _status;
  int? _selectedWarehouseId;
  final WarehouseService _warehouseService = WarehouseService();
  List<WarehouseModel> _warehouses = [];
  bool _isLoadingWarehouses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _maxWeightController = TextEditingController(text: widget.vehicle?.maxWeightKg.toString() ?? '');
    _maxVolumeController = TextEditingController(text: widget.vehicle?.maxVolumeM3.toString() ?? '');
    _vehicleType = widget.vehicle?.vehicleType ?? VehicleType.BIKE;
    _status = widget.vehicle?.status ?? VehicleStatus.ACTIVE;
    _selectedWarehouseId = widget.vehicle?.currentWarehouseId;
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await _warehouseService.getAllWarehouses();
      if (mounted) {
        setState(() {
          _warehouses = warehouses;
          _isLoadingWarehouses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWarehouses = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _maxWeightController.dispose();
    _maxVolumeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final licensePlate = _licensePlateController.text.trim();
    final maxWeight = double.parse(_maxWeightController.text.trim());
    final maxVolume = double.parse(_maxVolumeController.text.trim());

    try {
      if (widget.vehicle == null) {
        final request = VehicleCreateRequest(
          licensePlate: licensePlate,
          vehicleType: _vehicleType,
          maxWeightKg: maxWeight,
          maxVolumeM3: maxVolume,
          status: _status,
          currentWarehouseId: _selectedWarehouseId,
        );
        await widget.vehicleService.createVehicle(request);
      } else {
        final request = VehicleUpdateRequest(
          licensePlate: licensePlate,
          vehicleType: _vehicleType,
          maxWeightKg: maxWeight,
          maxVolumeM3: maxVolume,
          status: _status,
          currentWarehouseId: _selectedWarehouseId,
        );
        await widget.vehicleService.updateVehicle(widget.vehicle!.vehicleId, request);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle == null
                ? 'Tạo phương tiện thành công'
                : 'Cập nhật phương tiện thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(isEdit ? 'Chỉnh sửa phương tiện' : 'Thêm phương tiện mới'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Biển số xe *',
                    hintText: 'VD: 29A-123.45',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập biển số xe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleType>(
                  initialValue: _vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Loại phương tiện *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: VehicleType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  ).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _vehicleType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Tải trọng tối đa (kg) *',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tải trọng';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Tải trọng phải là số dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxVolumeController,
                  decoration: const InputDecoration(
                    labelText: 'Thể tích tối đa (m³) *',
                    prefixIcon: Icon(Icons.view_in_ar_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập thể tích';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Thể tích phải là số dương';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedWarehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Kho hiện tại',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không gán kho (Trống)'),
                    ),
                    ..._warehouses.map(
                      (w) => DropdownMenuItem<int?>(
                        value: w.warehouseId,
                        child: Text(w.name),
                      ),
                    ),
                  ],
                  onChanged: _isLoadingWarehouses ? null : (val) {
                    setState(() {
                      _selectedWarehouseId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái *',
                    prefixIcon: Icon(Icons.settings_suggest_outlined),
                  ),
                  items: VehicleStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  ).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _status = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
