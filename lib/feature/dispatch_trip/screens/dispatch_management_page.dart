import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/services/dispatch_management_service.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';
import 'package:smartlogisticssystem/feature/vehicle/service/vehicle_service.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/feature/route_config/service/route_config_service.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/create_linehaul_trip_dialog.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/create_pallet_dialog.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/edit_linehaul_trip_dialog.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/edit_local_trip_dialog.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/collapse_local_trip_dialog.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/trip_list_column.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/trip_details_column.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/widgets/resources_column.dart';



class DispatchManagementPage extends StatefulWidget {
  const DispatchManagementPage({super.key});

  @override
  State<DispatchManagementPage> createState() => _DispatchManagementPageState();
}

class _DispatchManagementPageState extends State<DispatchManagementPage> {
  final DispatchManagementService _dispatchService = DispatchManagementService();

  bool _isLinehaulSelected = true;
  List<LinehaulTripModel> _linehaulTrips = [];
  List<LocalTripModel> _localTrips = [];
  dynamic _selectedTrip; // Can be LinehaulTripModel or LocalTripModel
  bool _isLoadingTrips = true;

  List<OrderModel> _newOrders = [];
  List<PalletModel> _unassignedPallets = [];
  bool _isLoadingResources = true;

  List<VehicleModel> _allVehicles = [];
  List<DriverModel> _allDrivers = [];
  List<RouteConfigModel> _allRouteConfigs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingTrips = true;
      _isLoadingResources = true;
    });

    try {
      final linehaulRes = await _dispatchService.getAllLinehaulTrips();
      final localRes = await _dispatchService.getAllLocalTrips();
      final ordersRes = await _dispatchService.getOrdersByStatus('NEW');
      final palletsRes = await _dispatchService.getAllPallets();
      final vehiclesRes = await VehicleService().getAllVehicles();
      final driversRes = await _dispatchService.getAllDrivers();
      final routeConfigsRes = await RouteConfigService().getAllRouteConfigs();

      if (mounted) {
        setState(() {
          _linehaulTrips = linehaulRes;
          _localTrips = localRes;
          _newOrders = ordersRes;
          _unassignedPallets = palletsRes.where((p) => p.linehaulTrip == null).toList();
          _allVehicles = vehiclesRes;
          _allDrivers = driversRes;
          _allRouteConfigs = routeConfigsRes;
          _isLoadingTrips = false;
          _isLoadingResources = false;
        });
      }
    } catch (e) {
      print('Error loading dispatch data: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
          _isLoadingResources = false;
        });
      }
    }
  }

  Future<void> _refreshTripDetails() async {
    if (_selectedTrip is LinehaulTripModel) {
      final updated = await _dispatchService.getLinehaulTripById((_selectedTrip as LinehaulTripModel).linehaulId!);
      setState(() {
        _selectedTrip = updated;
      });
    } else if (_selectedTrip is LocalTripModel) {
      final updated = await _dispatchService.getLocalTripById((_selectedTrip as LocalTripModel).localTripId!);
      setState(() {
        _selectedTrip = updated;
      });
    }
    _loadData();
  }

  Color _getLinehaulStatusColor(LinehaulTripStatus? status) {
    switch (status) {
      case LinehaulTripStatus.PREPARING:
        return Colors.orange;
      case LinehaulTripStatus.EN_ROUTE:
        return Colors.blue;
      case LinehaulTripStatus.ARRIVED:
        return Colors.green;
      case LinehaulTripStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLocalStatusColor(LocalTripStatus? status) {
    switch (status) {
      case LocalTripStatus.PENDING_ACCEPTANCE:
        return Colors.orange;
      case LocalTripStatus.ACCEPTED:
        return Colors.blue;
      case LocalTripStatus.CANCELLED:
        return Colors.red;
      case LocalTripStatus.ASSIGNED:
        return Colors.indigo;
      case LocalTripStatus.EXECUTING:
        return Colors.amber;
      case LocalTripStatus.COMPLETED:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPalletStatusColor(String? statusStr) {
    if (statusStr == null) return Colors.grey;
    try {
      final status = PalletStatus.values.firstWhere((e) => e.name == statusStr);
      switch (status) {
        case PalletStatus.CREATING:
          return Colors.orange;
        case PalletStatus.SEALED:
          return Colors.blue;
        case PalletStatus.IN_TRANSIT:
          return Colors.indigo;
        case PalletStatus.ARRIVED:
          return Colors.green;
        case PalletStatus.CAN_SEAL:
          return Colors.brown;
      }
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getPalletStatusDisplayName(String? statusStr) {
    if (statusStr == null) return 'N/A';
    try {
      final status = PalletStatus.values.firstWhere((e) => e.name == statusStr);
      return status.displayName;
    } catch (_) {
      return statusStr;
    }
  }

  void _showEditLinehaulDialog(LinehaulTripModel trip) {
    showDialog(
      context: context,
      builder: (context) {
        return EditLinehaulTripDialog(
          trip: trip,
          allVehicles: _allVehicles,
          allDrivers: _allDrivers,
          onUpdate: (updateData) async {
            try {
              await _dispatchService.updateLinehaulTrip(trip.linehaulId!, updateData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật chuyến đi thành công!'), backgroundColor: Colors.green),
              );
              _refreshTripDetails();
            } catch (e) {
              String errorMsg = 'Lỗi cập nhật chuyến đi';
              if (e is DioException && e.response?.data != null) {
                errorMsg = e.response!.data['message'] ?? errorMsg;
              } else {
                errorMsg = e.toString();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
              rethrow;
            }
          },
        );
      },
    );
  }

  void _showEditLocalDialog(LocalTripModel trip) {
    showDialog(
      context: context,
      builder: (context) {
        return EditLocalTripDialog(
          trip: trip,
          allVehicles: _allVehicles,
          allDrivers: _allDrivers,
          onSave: (vehicleId, driverId) async {
            try {
              if (vehicleId != null && vehicleId != trip.vehicle?.vehicleId) {
                await _dispatchService.changeLocalTripVehicle(trip.localTripId!, vehicleId);
              }
              if (driverId != null && driverId != trip.driver?.driverId) {
                await _dispatchService.changeLocalTripDriver(trip.localTripId!, driverId);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật chuyến đi Last-Mile thành công!'), backgroundColor: Colors.green),
              );
              _refreshTripDetails();
            } catch (e) {
              String errorMsg = 'Lỗi cập nhật chuyến đi Last-Mile';
              if (e is DioException && e.response?.data != null) {
                errorMsg = e.response!.data['message'] ?? errorMsg;
              } else {
                errorMsg = e.toString();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
              rethrow;
            }
          },
        );
      },
    );
  }

  void _showCollapseLocalDialog(LocalTripModel trip) {
    showDialog(
      context: context,
      builder: (context) {
        return CollapseLocalTripDialog(
          trip: trip,
          localTrips: _localTrips,
          onCollapse: (targetTripId) async {
            try {
              await _dispatchService.collapseLocalTrip(trip.localTripId!, targetTripId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gộp chuyến Last-Mile thành công!'), backgroundColor: Colors.green),
              );
              setState(() {
                _selectedTrip = null;
              });
              _loadData();
            } catch (e) {
              String errorMsg = 'Lỗi gộp chuyến Last-Mile';
              if (e is DioException && e.response?.data != null) {
                errorMsg = e.response!.data['message'] ?? errorMsg;
              } else {
                errorMsg = e.toString();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
              rethrow;
            }
          },
        );
      },
    );
  }

  void _showCreateLinehaulTripDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CreateLinehaulTripDialog(
          allRouteConfigs: _allRouteConfigs,
          allVehicles: _allVehicles,
          allDrivers: _allDrivers,
          onCreate: (createData) async {
            try {
              await _dispatchService.createLinehaulTrip(createData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo chuyến đi thành công!'), backgroundColor: Colors.green),
              );
              _loadData();
            } catch (e) {
              String errorMsg = 'Lỗi tạo chuyến đi';
              if (e is DioException && e.response?.data != null) {
                errorMsg = e.response!.data['message'] ?? errorMsg;
              } else {
                errorMsg = e.toString();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
              rethrow;
            }
          },
        );
      },
    );
  }

  void _showCreatePalletDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CreatePalletDialog(
          allRouteConfigs: _allRouteConfigs,
          onCreate: (createData) async {
            try {
              await _dispatchService.createPallet(createData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo Pallet thành công!'), backgroundColor: Colors.green),
              );
              _loadData();
            } catch (e) {
              String errorMsg = 'Lỗi tạo Pallet';
              if (e is DioException && e.response?.data != null) {
                errorMsg = e.response!.data['message'] ?? errorMsg;
              } else {
                errorMsg = e.toString();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
              rethrow;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: Trip List
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: TripListColumn(
              isLinehaulSelected: _isLinehaulSelected,
              linehaulTrips: _linehaulTrips,
              localTrips: _localTrips,
              selectedTrip: _selectedTrip,
              isLoadingTrips: _isLoadingTrips,
              onSelectTrip: (trip) => setState(() => _selectedTrip = trip),
              onToggleLinehaul: (isLinehaul) => setState(() {
                _isLinehaulSelected = isLinehaul;
                _selectedTrip = null;
              }),
              onCreateTrip: () async {
                if (_isLinehaulSelected) {
                  _showCreateLinehaulTripDialog();
                } else {
                  try {
                    await _dispatchService.planLocalTrips();
                    _loadData();
                  } catch (e) {
                    String errorMsg = 'Lỗi lập kế hoạch Last-Mile';
                    if (e is DioException && e.response?.data != null) {
                      errorMsg = e.response!.data['message'] ?? errorMsg;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ),
          // Column 2: Trip Details
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: TripDetailsColumn(
                      selectedTrip: _selectedTrip,
                      onEditLinehaul: _selectedTrip is LinehaulTripModel
                          ? () => _showEditLinehaulDialog(_selectedTrip as LinehaulTripModel)
                          : null,
                      onEditLocal: _selectedTrip is LocalTripModel
                          ? () => _showEditLocalDialog(_selectedTrip as LocalTripModel)
                          : null,
                      onCollapseLocal: (_selectedTrip is LocalTripModel && (_selectedTrip as LocalTripModel).status == LocalTripStatus.CANCELLED)
                          ? () => _showCollapseLocalDialog(_selectedTrip as LocalTripModel)
                          : null,
                      onAddPalletToLinehaul: (linehaulId, palletId) async {
                        try {
                          await _dispatchService.addPalletToLinehaulTrip(linehaulId, palletId);
                          _refreshTripDetails();
                        } catch (e) {
                          String errorMsg = 'Lỗi thêm Pallet vào chuyến đi';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response!.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      },
                      onAddOrderToPallet: (palletId, orderCode) async {
                        try {
                          await _dispatchService.addOrderToPallet(palletId, orderCode);
                          _refreshTripDetails();
                        } catch (e) {
                          String errorMsg = 'Lỗi thêm đơn hàng vào Pallet';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response!.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      },
                      onDeleteLinehaul: (tripId) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc chắn muốn xóa chuyến xe này không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _dispatchService.deleteLinehaulTrip(tripId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Xóa chuyến xe thành công!'), backgroundColor: Colors.green),
                            );
                            setState(() {
                              _selectedTrip = null;
                            });
                            _loadData();
                          } catch (e) {
                            String errorMsg = 'Lỗi xóa chuyến xe';
                            if (e is DioException && e.response?.data != null) {
                              errorMsg = e.response!.data['message'] ?? errorMsg;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      onUpdateStatusToCanStart: (tripId) async {
                        try {
                          await _dispatchService.updateStatusToCanStart(tripId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cập nhật trạng thái chuyến xe thành công!'), backgroundColor: Colors.green),
                          );
                          _refreshTripDetails();
                        } catch (e) {
                          String errorMsg = 'Lỗi cập nhật trạng thái chuyến xe';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response!.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      },
                      onDeletePallet: (palletId) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc chắn muốn xóa Pallet này không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _dispatchService.deletePallet(palletId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Xóa Pallet thành công!'), backgroundColor: Colors.green),
                            );
                            _loadData();
                            if (_selectedTrip != null) {
                              _refreshTripDetails();
                            }
                          } catch (e) {
                            String errorMsg = 'Lỗi xóa Pallet';
                            if (e is DioException && e.response?.data != null) {
                              errorMsg = e.response!.data['message'] ?? errorMsg;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      onUpdateStatusToCanSeal: (palletId) async {
                        try {
                          await _dispatchService.updateStatusToCanSeal(palletId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cập nhật trạng thái Pallet thành công!'), backgroundColor: Colors.green),
                          );
                          _loadData();
                          if (_selectedTrip != null) {
                            _refreshTripDetails();
                          }
                        } catch (e) {
                          String errorMsg = 'Lỗi cập nhật trạng thái Pallet';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response!.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: _buildWaitingPalletsSection(),
                  ),
                ],
              ),
            ),
          ),
          // Column 3: Resources (Orders Pool)
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: AppColors.darkest,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: ResourcesColumn(
              isLoadingResources: _isLoadingResources,
              newOrders: _newOrders,
              onRemoveOrderFromPallet: (palletId, orderCode) async {
                try {
                  await _dispatchService.removeOrderFromPallet(palletId, orderCode);
                  _loadData();
                  _refreshTripDetails();
                } catch (e) {
                  String errorMsg = 'Lỗi xóa đơn hàng khỏi Pallet';
                  if (e is DioException && e.response?.data != null) {
                    errorMsg = e.response!.data['message'] ?? errorMsg;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPalletsSection() {
    return DragTarget<PalletModel>(
      onAccept: (pallet) async {
        int? tripId = pallet.linehaulTrip?.linehaulId;
        if (tripId == null && _selectedTrip is LinehaulTripModel) {
          tripId = (_selectedTrip as LinehaulTripModel).linehaulId;
        }
        if (pallet.palletId != null && tripId != null) {
          try {
            await _dispatchService.removePalletFromLinehaulTrip(tripId, pallet.palletId!);
            _loadData();
            _refreshTripDetails();
          } catch (e) {
            String errorMsg = 'Lỗi xóa Pallet khỏi chuyến đi';
            if (e is DioException && e.response?.data != null) {
              errorMsg = e.response!.data['message'] ?? errorMsg;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppColors.success.withOpacity(0.1) : Colors.white,
            border: Border.all(color: candidateData.isNotEmpty ? AppColors.success : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Pallet chờ xếp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_unassignedPallets.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _showCreatePalletDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo Pallet'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoadingResources
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _unassignedPallets.length,
                        itemBuilder: (context, index) {
                          final pallet = _unassignedPallets[index];
                          return _buildDraggablePallet(pallet);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggablePallet(PalletModel pallet) {
    return Draggable<PalletModel>(
      data: pallet,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(pallet.palletCode ?? 'Pallet', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildUnassignedPalletCard(pallet),
      ),
      child: _buildUnassignedPalletCard(pallet),
    );
  }

  Widget _buildUnassignedPalletCard(PalletModel pallet) {
    final bool isEmpty = (pallet.palletItems?.length ?? 0) == 0;

    return DragTarget<OrderModel>(
      onAccept: (order) async {
        if (pallet.palletId != null && order.orderCode != null) {
          try {
            await _dispatchService.addOrderToPallet(pallet.palletId!, order.orderCode!);
            _loadData();
          } catch (e) {
            String errorMsg = 'Lỗi thêm đơn hàng vào Pallet';
            if (e is DioException && e.response?.data != null) {
              errorMsg = e.response!.data['message'] ?? errorMsg;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppColors.success.withOpacity(0.1) : Colors.white,
            border: Border.all(color: candidateData.isNotEmpty ? AppColors.success : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
            title: Text(pallet.palletCode ?? 'Unknown Pallet', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            subtitle: Text('${pallet.palletItems?.length ?? 0} kiện • ${pallet.totalWeightKg ?? 0}kg', style: const TextStyle(color: AppColors.textSecondary)),
            shape: const Border(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pallet.status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPalletStatusColor(pallet.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPalletStatusDisplayName(pallet.status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPalletStatusColor(pallet.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Chờ xếp xe', style: TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],
                if (pallet.status == 'CREATING') ...[
                  IconButton(
                    icon: const Icon(Icons.lock_open, size: 18, color: AppColors.primary),
                    onPressed: pallet.palletId != null
                        ? () async {
                            try {
                              await _dispatchService.updateStatusToCanSeal(pallet.palletId!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cập nhật trạng thái Pallet thành công!'), backgroundColor: Colors.green),
                              );
                              _loadData();
                              if (_selectedTrip != null) {
                                _refreshTripDetails();
                              }
                            } catch (e) {
                              String errorMsg = 'Lỗi cập nhật trạng thái Pallet';
                              if (e is DioException && e.response?.data != null) {
                                errorMsg = e.response!.data['message'] ?? errorMsg;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                              );
                            }
                          }
                        : null,
                    tooltip: 'Sẵn sàng niêm phong (Can Seal)',
                  ),
                ],
                if (pallet.palletId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text('Bạn có chắc chắn muốn xóa Pallet này không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _dispatchService.deletePallet(pallet.palletId!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Xóa Pallet thành công!'), backgroundColor: Colors.green),
                          );
                          _loadData();
                          if (_selectedTrip != null) {
                            _refreshTripDetails();
                          }
                        } catch (e) {
                          String errorMsg = 'Lỗi xóa Pallet';
                          if (e is DioException && e.response?.data != null) {
                            errorMsg = e.response!.data['message'] ?? errorMsg;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    tooltip: 'Xóa Pallet',
                  ),
              ],
            ),
            children: isEmpty
                ? [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('Pallet trống. Kéo thả đơn hàng vào đây.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    )
                  ]
                : pallet.palletItems?.map((item) {
                    final order = item.order;
                    if (order == null) return const SizedBox();
                    return Draggable<DraggedPalletItem>(
                      data: DraggedPalletItem(palletId: pallet.palletId!, order: order),
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Order #${order.orderCode ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: ListTile(
                          title: Text('Order #${order.orderCode ?? "N/A"}', style: const TextStyle(color: AppColors.textPrimary)),
                        ),
                      ),
                      child: ListTile(
                        title: Text('Order #${order.orderCode ?? "N/A"}', style: const TextStyle(color: AppColors.textPrimary)),
                        trailing: const Icon(Icons.drag_indicator, size: 16, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList() ?? [],
          ),
        );
      },
    );
  }
}

class DraggedPalletItem {
  final int palletId;
  final OrderModel order;
  DraggedPalletItem({required this.palletId, required this.order});
}

