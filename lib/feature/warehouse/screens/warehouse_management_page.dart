import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/warehouse/service/warehouse_service.dart';

class WarehouseManagementPage extends StatefulWidget {
  const WarehouseManagementPage({super.key});

  @override
  State<WarehouseManagementPage> createState() => _WarehouseManagementPageState();
}

class _WarehouseManagementPageState extends State<WarehouseManagementPage> {
  final WarehouseService _warehouseService = WarehouseService();
  List<WarehouseModel> _allWarehouses = [];
  List<WarehouseModel> _filteredWarehouses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter
  String? _selectedProvinceFilter;
  List<String> _provinces = [];
  bool _isLoadingProvinces = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProvinces();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _warehouseService.getAllWarehouses();
      if (mounted) {
        setState(() {
          _allWarehouses = data;
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

  Future<void> _loadProvinces() async {
    try {
      final response = await Dio().get('https://provinces.open-api.vn/api/v2/p/');
      if (response.statusCode == 200 && response.data is List) {
        final List data = response.data;
        if (mounted) {
          setState(() {
            _provinces = data.map((e) => e['name'].toString()).toList();
            _isLoadingProvinces = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
      if (mounted) {
        setState(() {
          _isLoadingProvinces = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredWarehouses = _allWarehouses.where((warehouse) {
        final matchesProvince = _selectedProvinceFilter == null || warehouse.province == _selectedProvinceFilter;
        return matchesProvince;
      }).toList();
    });
  }

  Future<void> _deleteWarehouse(WarehouseModel warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhà kho "${warehouse.name}" không?'),
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
      await _warehouseService.deleteWarehouse(warehouse.warehouseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa nhà kho thành công'),
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

  void _showWarehouseDialog([WarehouseModel? warehouse]) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WarehouseFormDialog(
        warehouse: warehouse,
        warehouseService: _warehouseService,
        provinces: _provinces,
      ),
    ).then((success) {
      if (success == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Quản lý nhà kho')),
                    ElevatedButton.icon(
                      onPressed: () => _showWarehouseDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm nhà kho'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filters Bar
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedProvinceFilter,
                        hint: const Text('Lọc theo Tỉnh / Thành phố'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tất cả Tỉnh / Thành phố'),
                          ),
                          ..._provinces.map(
                            (prov) => DropdownMenuItem<String>(
                              value: prov,
                              child: Text(prov),
                            ),
                          ),
                        ],
                        onChanged: _isLoadingProvinces ? null : (val) {
                          setState(() {
                            _selectedProvinceFilter = val;
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
                else if (_filteredWarehouses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Text(
                        'Không tìm thấy nhà kho nào',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ),
                  )
                else
                  DarkTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Tên nhà kho')),
                      DataColumn(label: Text('Phân loại')),
                      DataColumn(label: Text('Địa chỉ')),
                      DataColumn(label: Text('Tỉnh / Thành phố')),
                      DataColumn(label: Text('Tọa độ (Lat, Lng)')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: _filteredWarehouses
                        .map(
                          (warehouse) => DataRow(
                            cells: [
                              DataCell(Text(warehouse.warehouseId.toString())),
                              DataCell(
                                Text(
                                  warehouse.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: warehouse.type == WarehouseType.CDC
                                        ? Colors.orange.shade50
                                        : Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: warehouse.type == WarehouseType.CDC
                                          ? Colors.orange.shade300
                                          : Colors.teal.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    warehouse.type.displayName,
                                    style: TextStyle(
                                      color: warehouse.type == WarehouseType.CDC
                                          ? Colors.orange.shade800
                                          : Colors.teal.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(warehouse.address)),
                              DataCell(Text(warehouse.province)),
                              DataCell(Text('${warehouse.latitude.toStringAsFixed(6)}, ${warehouse.longitude.toStringAsFixed(6)}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showWarehouseDialog(warehouse),
                                      icon: const Icon(Icons.edit_outlined),
                                      color: AppColors.primary,
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteWarehouse(warehouse),
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
          const SizedBox(height: 24),
          // Map displaying all warehouses at the bottom
          if (!_isLoading && _filteredWarehouses.isNotEmpty)
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Bản đồ vị trí các nhà kho'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 450,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                        ),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _filteredWarehouses.map((w) => w.latitude).reduce((a, b) => a + b) / _filteredWarehouses.length,
                              _filteredWarehouses.map((w) => w.longitude).reduce((a, b) => a + b) / _filteredWarehouses.length,
                            ),
                            initialZoom: 6.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                            ),
                            MarkerLayer(
                              markers: _filteredWarehouses.map((warehouse) {
                                return Marker(
                                  point: LatLng(warehouse.latitude, warehouse.longitude),
                                  width: 200,
                                  height: 80,
                                  child: Tooltip(
                                    message: '${warehouse.name}\n${warehouse.address}',
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            warehouse.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.location_on,
                                          color: warehouse.type == WarehouseType.CDC ? Colors.orange : Colors.teal,
                                          size: 32,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WarehouseFormDialog extends StatefulWidget {
  final WarehouseModel? warehouse;
  final WarehouseService warehouseService;
  final List<String> provinces;

  const _WarehouseFormDialog({
    this.warehouse,
    required this.warehouseService,
    required this.provinces,
  });

  @override
  State<_WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late WarehouseType _type;
  String? _selectedProvince;
  bool _isSaving = false;

  final MapController _mapController = MapController();
  LatLng _markerPosition = const LatLng(10.762622, 106.660172); // Default HCMC

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse?.name ?? '');
    _addressController = TextEditingController(text: widget.warehouse?.address ?? '');
    _latitudeController = TextEditingController(text: widget.warehouse?.latitude.toString() ?? '10.762622');
    _longitudeController = TextEditingController(text: widget.warehouse?.longitude.toString() ?? '106.660172');
    _type = widget.warehouse?.type ?? WarehouseType.CDC;
    _selectedProvince = widget.warehouse?.province;

    if (widget.warehouse != null) {
      _markerPosition = LatLng(widget.warehouse!.latitude, widget.warehouse!.longitude);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _markerPosition = point;
      _latitudeController.text = point.latitude.toStringAsFixed(6);
      _longitudeController.text = point.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Tỉnh / Thành phố'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final lat = double.parse(_latitudeController.text.trim());
    final lng = double.parse(_longitudeController.text.trim());

    try {
      if (widget.warehouse == null) {
        final request = WarehouseCreateRequest(
          name: name,
          type: _type,
          address: address,
          province: _selectedProvince!,
          latitude: lat,
          longitude: lng,
        );
        await widget.warehouseService.createWarehouse(request);
      } else {
        final request = WarehouseUpdateRequest(
          name: name,
          type: _type,
          address: address,
          province: _selectedProvince!,
          latitude: lat,
          longitude: lng,
        );
        await widget.warehouseService.updateWarehouse(widget.warehouse!.warehouseId, request);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.warehouse == null
                ? 'Tạo nhà kho thành công'
                : 'Cập nhật nhà kho thành công'),
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
    final isEdit = widget.warehouse != null;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(isEdit ? 'Chỉnh sửa nhà kho' : 'Thêm nhà kho mới'),
      content: SizedBox(
        width: 1000,
        height: 650,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Form Fields
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên nhà kho *',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tên nhà kho';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<WarehouseType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Loại nhà kho *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: WarehouseType.values.map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ),
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _type = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedProvince,
                        hint: const Text('Chọn Tỉnh / Thành phố *'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: widget.provinces.map(
                          (prov) => DropdownMenuItem(
                            value: prov,
                            child: Text(prov),
                          ),
                        ).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProvince = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Vĩ độ (Latitude) *',
                          prefixIcon: Icon(Icons.navigation_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.trim());
                          if (parsed != null) {
                            setState(() {
                              _markerPosition = LatLng(parsed, _markerPosition.longitude);
                              _mapController.move(_markerPosition, _mapController.camera.zoom);
                            });
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc nhập vĩ độ';
                          }
                          if (double.tryParse(val.trim()) == null) {
                            return 'Phải là chữ số';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Kinh độ (Longitude) *',
                          prefixIcon: Icon(Icons.navigation_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.trim());
                          if (parsed != null) {
                            setState(() {
                              _markerPosition = LatLng(_markerPosition.latitude, parsed);
                              _mapController.move(_markerPosition, _mapController.camera.zoom);
                            });
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc nhập kinh độ';
                          }
                          if (double.tryParse(val.trim()) == null) {
                            return 'Phải là chữ số';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Interactive Map
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn vị trí trên bản đồ để tự động lấy tọa độ Lat, Lng:',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                        ),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _markerPosition,
                            initialZoom: 12.0,
                            onTap: (tapPosition, point) => _onMapTap(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _markerPosition,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
