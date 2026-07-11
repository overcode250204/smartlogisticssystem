import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/services/dispatch_management_service.dart';

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

      if (mounted) {
        setState(() {
          _linehaulTrips = linehaulRes;
          _localTrips = localRes;
          _newOrders = ordersRes;
          // Filter unassigned pallets (assuming linehaulTrip is null means unassigned)
          _unassignedPallets = palletsRes.where((p) => p.linehaulTrip == null).toList();
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

  void _showEditLinehaulDialog(LinehaulTripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Linehaul Trip #${trip.linehaulId}'),
        content: const Text('Edit driver, vehicle, and other info here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement updateLinehaulTrip logic
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
            child: _buildTripListColumn(),
          ),
          // Column 2: Trip Details
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTripDetailsColumn(),
            ),
          ),
          // Column 3: Resources (Orders & Pallets)
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: AppColors.darkest,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: _buildResourcesColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripListColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách Chuyến đi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () {
                  if (_isLinehaulSelected) {
                    _dispatchService.createLinehaulTrip({}).then((_) => _loadData());
                  } else {
                    _dispatchService.planLocalTrips().then((_) => _loadData());
                  }
                },
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                tooltip: 'Tạo Chuyến đi',
              ),
            ],
          ),
        ),
        // Toggle Linehaul / Last-Mile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isLinehaulSelected = true;
                      _selectedTrip = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isLinehaulSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isLinehaulSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 16, color: _isLinehaulSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Linehaul',
                            style: TextStyle(
                              color: _isLinehaulSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: _isLinehaulSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isLinehaulSelected = false;
                      _selectedTrip = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isLinehaulSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isLinehaulSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.electric_moped_outlined,
                              size: 16, color: !_isLinehaulSelected ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Last-Mile',
                            style: TextStyle(
                              color: !_isLinehaulSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: !_isLinehaulSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: 'Tất cả Trạng thái',
                      items: ['Tất cả Trạng thái', 'Đang chuẩn bị', 'Sẵn sàng'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: 'Tất cả Ca',
                      items: ['Tất cả Ca', 'Ca 1', 'Ca 2'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm mã chuyến, tuyến đường...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _isLinehaulSelected ? _linehaulTrips.length : _localTrips.length,
                  itemBuilder: (context, index) {
                    if (_isLinehaulSelected) {
                      return _buildLinehaulCard(_linehaulTrips[index]);
                    } else {
                      return _buildLocalCard(_localTrips[index]);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLinehaulCard(LinehaulTripModel trip) {
    final isSelected = _selectedTrip == trip;
    // Calculate total weight (mocking based on pallets if needed, or use a field if exists)
    double currentWeight = 0;
    for (var p in trip.pallets ?? []) {
      currentWeight += p.totalWeightKg ?? 0;
    }
    double maxWeight = trip.vehicle?.maxWeightKg ?? 500.0;
    if (maxWeight == 0) maxWeight = 500.0;
    double progress = (currentWeight / maxWeight).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => setState(() => _selectedTrip = trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TR-${trip.linehaulId ?? "000"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: trip.status == 'Đang chuẩn bị' ? Colors.orange.shade50 : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip.status ?? 'Đang chuẩn bị',
                    style: TextStyle(
                      fontSize: 10,
                      color: trip.status == 'Đang chuẩn bị' ? Colors.orange.shade800 : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.routeConfig?.routeName ?? 'Unknown Route',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ca: 1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('${currentWeight.toStringAsFixed(0)} / ${maxWeight.toStringAsFixed(0)} kg (${(progress * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? Colors.red : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalCard(LocalTripModel trip) {
    final isSelected = _selectedTrip == trip;

    return GestureDetector(
      onTap: () => setState(() => _selectedTrip = trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LM-${trip.localTripId ?? "000"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: trip.status == 'Đang chuẩn bị' ? Colors.orange.shade50 : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip.status ?? 'Đang chuẩn bị',
                    style: TextStyle(
                      fontSize: 10,
                      color: trip.status == 'Đang chuẩn bị' ? Colors.orange.shade800 : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.hub?.name ?? 'Unknown Area',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Ca: 1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            // Progress bar removed for last mile as per feedback
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailsColumn() {
    if (_selectedTrip == null) {
      return const Center(
        child: Text('Chọn một chuyến đi để xem chi tiết', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    if (_selectedTrip is LinehaulTripModel) {
      final trip = _selectedTrip as LinehaulTripModel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripHeader(
            'TR-${trip.linehaulId ?? "000"}',
            'LINEHAUL',
            trip.routeConfig?.routeName ?? 'Unknown Route',
            trip.linehaulTripDriver?.isNotEmpty == true ? trip.linehaulTripDriver![0].driver?.name : null,
            trip.vehicle?.licensePlate,
            onEdit: () => _showEditLinehaulDialog(trip),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DragTarget<PalletModel>(
              onAccept: (pallet) async {
                if (pallet.palletId != null && trip.linehaulId != null) {
                  await _dispatchService.addPalletToLinehaulTrip(trip.linehaulId!, pallet.palletId!);
                  _refreshTripDetails();
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: candidateData.isNotEmpty ? AppColors.primary : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text('Danh sách Pallet trên xe (${trip.pallets?.length ?? 0})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: trip.pallets?.length ?? 0,
                          itemBuilder: (context, index) {
                            final pallet = trip.pallets![index];
                            return _buildLinehaulPalletCard(pallet);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      final trip = _selectedTrip as LocalTripModel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTripHeader(
            'LM-${trip.localTripId ?? "000"}',
            'LAST-MILE',
            trip.hub?.name ?? 'Unknown Area',
            trip.driver?.name,
            trip.vehicle?.licensePlate,
            onEdit: null, // Read-only for last mile
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text('Danh sách Đơn hàng (VRP Order)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: trip.details?.length ?? 0,
                    itemBuilder: (context, index) {
                      final detail = trip.details![index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.darkest,
                            child: Text('${index + 1}', style: const TextStyle(color: AppColors.textPrimary)),
                          ),
                          title: Text(detail.order?.orderCode ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${detail.order?.totalWeightKg ?? 0}kg • ${detail.order?.deliveryProvince ?? ""}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTripHeader(String title, String typeLabel, String subtitle, String? driver, String? vehicle, {VoidCallback? onEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(typeLabel, style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Row(
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: onEdit,
                    tooltip: 'Edit Trip',
                  ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Text('XUẤT BẾN'),
                  label: const Icon(Icons.play_arrow),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(Icons.person_outline, driver ?? 'Chưa phân công', '0901234567'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoBox(Icons.local_shipping_outlined, 'Biển số xe', vehicle ?? 'Chưa phân công'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoBox(Icons.lock_outline, 'Chưa đóng Seal', ''),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.darkest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinehaulPalletCard(PalletModel pallet) {
    return DragTarget<OrderModel>(
      onAccept: (order) async {
        if (pallet.palletId != null && order.orderCode != null) {
          await _dispatchService.addOrderToPallet(pallet.palletId!, order.orderCode!);
          _refreshTripDetails();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppColors.success.withOpacity(0.1) : Colors.white,
            border: Border.all(color: candidateData.isNotEmpty ? AppColors.success : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2, color: AppColors.textSecondary),
            title: Text(pallet.palletCode ?? 'Unknown Pallet', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${pallet.palletItems?.length ?? 0} kiện • ${pallet.totalWeightKg ?? 0}kg'),
            shape: const Border(),
            children: pallet.palletItems?.map((item) => ListTile(
              title: Text('Order #${item.order?.orderCode ?? "Unknown"}'),
            )).toList() ?? [],
          ),
        );
      },
    );
  }

  Widget _buildResourcesColumn() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top Half: Order Pool
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Bể chứa Đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                      child: Text('${_newOrders.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Kéo thả đơn hàng vào chuyến xe hoặc pallet chờ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoadingResources
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _newOrders.length,
                          itemBuilder: (context, index) {
                            final order = _newOrders[index];
                            return _buildDraggableOrder(order);
                          },
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          // Bottom Half: Waiting Pallets
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Pallet chờ xếp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_unassignedPallets.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Create empty pallet
                        _dispatchService.createPallet({
                          "weight": 0.0,
                          "volume": 0.0,
                        }).then((_) => _loadData());
                      },
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
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOrder(OrderModel order) {
    return Draggable<OrderModel>(
      data: order,
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
          child: Text(order.orderCode ?? 'Order', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildOrderCard(order),
      ),
      child: _buildOrderCard(order),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderCode ?? 'Tài liệu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('${order.totalWeightKg ?? 0}kg • ${order.deliveryProvince ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('NEW', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
          await _dispatchService.addOrderToPallet(pallet.palletId!, order.orderCode!);
          _loadData();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(pallet.palletCode ?? 'Unknown Pallet', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Chờ xếp xe', style: TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (isEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid), // Should be dashed if possible, solid for now
                  ),
                  child: const Center(
                    child: Text('Pallet trống. Kéo thả đơn hàng vào đây.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: Row(
                    children: [
                      Text('${pallet.palletItems?.length ?? 0} kiện • ${pallet.totalWeightKg ?? 0}kg', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
