import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/feature/route_config/service/route_config_service.dart';
import 'package:smartlogisticssystem/feature/route_config/screens/create_route_config_dialog.dart';
import 'package:data_table_2/data_table_2.dart';


class RouteConfigManagementPage extends StatefulWidget {
  const RouteConfigManagementPage({super.key});

  @override
  State<RouteConfigManagementPage> createState() => _RouteConfigManagementPageState();
}

class _RouteConfigManagementPageState extends State<RouteConfigManagementPage> {
  final RouteConfigService _routeConfigService = RouteConfigService();
  List<RouteConfigModel> _routeConfigs = [];
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
      final data = await _routeConfigService.getAllRouteConfigs();
      if (mounted) {
        setState(() {
          _routeConfigs = data;
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

  Future<void> _deleteRouteConfig(RouteConfigModel config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa cấu hình tuyến "${config.routeName}" không?'),
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
      await _routeConfigService.deleteRouteConfig(config.routeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa cấu hình tuyến đường thành công'),
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

  Future<void> _toggleRouteConfigStatus(RouteConfigModel rc, bool newStatus) async {
    try {
      final updateReq = RouteConfigUpdateRequest(
        routeName: rc.routeName,
        fromWarehouseId: rc.fromWarehouse.warehouseId,
        toWarehouseId: rc.toWarehouse.warehouseId,
        dispatchType: rc.dispatchType,
        fixedDispatchTime: rc.fixedDispatchTime,
        minCapacityPercentage: rc.minCapacityPercentage,
        cutoffTime: rc.cutoffTime,
        maxWaitingDays: rc.maxWaitingDays,
        defaultVehicleId: rc.defaultVehicle?.vehicleId,
        provinceNames: rc.provinceNames,
        isActive: newStatus,
      );
      
      await _routeConfigService.updateRouteConfig(rc.routeId, updateReq);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStatus ? "Kích hoạt" : "Hủy kích hoạt"} tuyến đường thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thay đổi trạng thái: ${apiErrorMessage(e)}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showCreateDialog([RouteConfigModel? config]) {
    showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateRouteConfigDialog(routeConfig: config),
    ).then((result) async {
      if (result != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          if (config == null) {
            final createReq = RouteConfigCreateRequest(
              routeName: result['routeName'],
              fromWarehouseId: result['fromWarehouseId'],
              toWarehouseId: result['toWarehouseId'],
              dispatchType: result['dispatchType'],
              fixedDispatchTime: result['fixedDispatchTime'],
              minCapacityPercentage: result['minCapacityPercentage'],
              cutoffTime: result['cutoffTime'],
              maxWaitingDays: result['maxWaitingDays'],
              defaultVehicleId: result['defaultVehicleId'],
              provinceNames: result['provinceNames'],
              isActive: result['isActive'],
            );
            await _routeConfigService.createRouteConfig(createReq);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tạo cấu hình tuyến đường thành công'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } else {
            final updateReq = RouteConfigUpdateRequest(
              routeName: result['routeName'],
              fromWarehouseId: result['fromWarehouseId'],
              toWarehouseId: result['toWarehouseId'],
              dispatchType: result['dispatchType'],
              fixedDispatchTime: result['fixedDispatchTime'],
              minCapacityPercentage: result['minCapacityPercentage'],
              cutoffTime: result['cutoffTime'],
              maxWaitingDays: result['maxWaitingDays'],
              defaultVehicleId: result['defaultVehicleId'],
              provinceNames: result['provinceNames'],
              isActive: result['isActive'],
            );
            await _routeConfigService.updateRouteConfig(config.routeId, updateReq);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cập nhật cấu hình tuyến đường thành công'),
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

  String _getScheduleDetails(RouteConfigModel rc) {
    final buffer = StringBuffer();
    buffer.write('Cutoff: ${rc.cutoffTime}');
    if (rc.dispatchType == DispatchType.TIME || rc.dispatchType == DispatchType.HYBRID) {
      if (rc.fixedDispatchTime != null) {
        buffer.write('\nXuất bến: ${rc.fixedDispatchTime}');
      }
    }
    if (rc.dispatchType == DispatchType.CAPACITY || rc.dispatchType == DispatchType.HYBRID) {
      if (rc.minCapacityPercentage != null) {
        buffer.write('\nTải trọng tối thiểu: ${rc.minCapacityPercentage}%');
      }
      if (rc.maxWaitingDays != null) {
        buffer.write('\nChờ tối đa: ${rc.maxWaitingDays} ngày');
      }
    }
    return buffer.toString();
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

    if (_errorMessage != null && _routeConfigs.isEmpty) {
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

    return PageScroll(
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle('Quản lý Cấu hình tuyến đường (RouteConfigs)')),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: const Icon(Icons.add_road),
                  label: const Text('Thêm cấu hình tuyến'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_routeConfigs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Chưa có tuyến đường nào được cấu hình',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: AppColors.border,
                ),
                child: SizedBox(
                  height: 650,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1300,
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.darkest.withValues(alpha: 0.55),
                    ),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    dataRowHeight: 64,
                    headingRowHeight: 56,
                    columns: const [
                      DataColumn2(label: Text('ID'), size: ColumnSize.S),
                      DataColumn2(label: Text('Tên tuyến'), size: ColumnSize.M),
                      DataColumn2(label: Text('Tuyến đi (Từ -> Đến)'), size: ColumnSize.L),
                      DataColumn2(label: Text('SLA'), size: ColumnSize.S),
                      DataColumn2(label: Text('Loại điều phối'), size: ColumnSize.M),
                      DataColumn2(label: Text('Trạng thái'), size: ColumnSize.S),
                      DataColumn2(label: Text('Xe mặc định'), size: ColumnSize.M),
                      DataColumn2(label: Text('Chi tiết lịch trình'), size: ColumnSize.L),
                      DataColumn2(label: Text('Tỉnh/Thành đi qua'), size: ColumnSize.L),
                      DataColumn2(label: Text('Thao tác'), size: ColumnSize.S),
                    ],
                    rows: _routeConfigs
                        .map(
                          (rc) => DataRow(
                            cells: [
                              DataCell(Text(rc.routeId.toString())),
                              DataCell(Text(rc.routeName)),
                              DataCell(Text('${rc.fromWarehouse.name} ➔ ${rc.toWarehouse.name}')),
                              DataCell(Text(rc.slaHours != null ? '${rc.slaHours}h' : 'Tính toán...')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rc.dispatchType.displayName,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Switch.adaptive(
                                  value: rc.isActive,
                                  activeColor: AppColors.success,
                                  onChanged: (val) => _toggleRouteConfigStatus(rc, val),
                                ),
                              ),
                              DataCell(Text(
                                rc.defaultVehicle != null 
                                    ? '${rc.defaultVehicle!.licensePlate} (${rc.defaultVehicle!.vehicleType.displayName})'
                                    : 'Chưa cấu hình',
                              )),
                              DataCell(Text(
                                _getScheduleDetails(rc),
                                style: const TextStyle(fontSize: 12),
                              )),
                              DataCell(
                                rc.provinceNames.isEmpty
                                    ? const Text('Trống', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))
                                    : Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: rc.provinceNames.map((p) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.border,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(p, style: const TextStyle(fontSize: 11)),
                                          );
                                        }).toList(),
                                      ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showCreateDialog(rc),
                                      icon: const Icon(Icons.edit_outlined),
                                      color: AppColors.primary,
                                      tooltip: 'Chỉnh sửa tuyến',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteRouteConfig(rc),
                                      icon: const Icon(Icons.delete_outline),
                                      color: AppColors.danger,
                                      tooltip: 'Xóa cấu hình tuyến',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
