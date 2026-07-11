import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/order/service/order_service.dart';
import 'package:smartlogisticssystem/feature/order/screens/edit_order_dialog.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL';

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
      final data = await _orderService.getAllOrders();
      if (mounted) {
        setState(() {
          _orders = data;
          _applyFilters();
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredOrders = _orders.where((order) {
        final matchesSearch = order.orderCode.toLowerCase().contains(query) ||
            order.customerName.toLowerCase().contains(query) ||
            order.phone.contains(query);
        final matchesStatus = _selectedStatusFilter == 'ALL' ||
            order.status.toUpperCase() == _selectedStatusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xác nhận hủy'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng "${order.orderCode}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.cancelOrder(order.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hủy đơn hàng ${order.orderCode} thành công'),
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
            content: Text('Lỗi khi hủy đơn hàng: ${apiErrorMessage(e)}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chi tiết đơn hàng: ${order.orderCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.barcodeUrl != null) ...[
                  Center(
                    child: Image.network(
                      order.barcodeUrl!,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.qr_code, size: 80),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _DetailRow(label: 'Trạng thái', value: _statusBadge(order.status)),
                _DetailRow(label: 'Khách hàng', value: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                _DetailRow(label: 'Số điện thoại', value: Text(order.phone)),
                _DetailRow(label: 'Địa chỉ giao hàng', value: Text(order.deliveryAddress)),
                _DetailRow(label: 'Tỉnh/Thành phố', value: Text(order.deliveryProvince)),
                _DetailRow(label: 'Kinh độ/Vĩ độ', value: Text('${order.longitude} / ${order.latitude}')),
                _DetailRow(
                  label: 'Tuyến đường',
                  value: Text(order.routeConfig?.routeName ?? 'Chưa cấu hình'),
                ),
                _DetailRow(
                  label: 'HUB phụ trách',
                  value: Text(order.assignedHub?.name ?? 'Chưa phân công'),
                ),
                _DetailRow(
                  label: 'Thanh toán',
                  value: Text(order.paymentType),
                ),
                _DetailRow(
                  label: 'Khối lượng / Thể tích',
                  value: Text('${order.totalWeightKg} kg / ${order.totalVolumeM3} m³'),
                ),
                _DetailRow(
                  label: 'Tổng tiền',
                  value: Text(
                    '${order.totalAmount.toStringAsFixed(0)} ₫',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                  ),
                ),
                if (order.proofUrl != null && order.proofUrl!.isNotEmpty) ...[
                  _DetailRow(
                    label: 'Ảnh minh chứng',
                    value: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          order.proofUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: Text('Lỗi tải ảnh minh chứng')),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Sản phẩm trong đơn hàng:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: AppColors.border, width: 0.5),
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...order.items.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(item.productName),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(item.quantityOrdered.toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${item.unitPrice.toStringAsFixed(0)} ₫'),
                            ),
                          ],
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status.toUpperCase()) {
      case 'NEW':
        color = Colors.blue;
        text = 'Mới tạo';
        break;
      case 'READY_TO_PICK':
        color = Colors.indigo;
        text = 'Chờ lấy hàng';
        break;
      case 'IN_PALLET':
        color = Colors.orange;
        text = 'Đã đóng pallet';
        break;
      case 'IN_TRANSIT_LINEHAUL':
        color = Colors.purple;
        text = 'Vận chuyển liên tỉnh';
        break;
      case 'ARRIVED_AT_HUB':
        color = Colors.teal;
        text = 'Đã đến HUB';
        break;
      case 'IN_TRANSIT_LOCAL':
        color = Colors.cyan;
        text = 'Đang giao hàng';
        break;
      case 'ARRIVED_AT_DELIVERY_POINT':
        color = Colors.lightGreen;
        text = 'Đã đến điểm giao';
        break;
      case 'DELIVERED':
        color = AppColors.success;
        text = 'Thành công';
        break;
      case 'FAILED':
        color = AppColors.danger;
        text = 'Thất bại';
        break;
      case 'CANCELLED':
        color = Colors.grey;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.black54;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý đơn hàng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Tìm kiếm theo mã đơn, khách hàng, số điện thoại...',
                        ),
                        onChanged: (val) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'NEW', child: Text('Mới tạo')),
                          DropdownMenuItem(value: 'READY_TO_PICK', child: Text('Chờ lấy hàng')),
                          DropdownMenuItem(value: 'IN_PALLET', child: Text('Đã đóng pallet')),
                          DropdownMenuItem(value: 'IN_TRANSIT_LINEHAUL', child: Text('Vận chuyển liên tỉnh')),
                          DropdownMenuItem(value: 'ARRIVED_AT_HUB', child: Text('Đã đến HUB')),
                          DropdownMenuItem(value: 'IN_TRANSIT_LOCAL', child: Text('Đang giao hàng')),
                          DropdownMenuItem(value: 'ARRIVED_AT_DELIVERY_POINT', child: Text('Đã đến điểm giao')),
                          DropdownMenuItem(value: 'DELIVERED', child: Text('Thành công')),
                          DropdownMenuItem(value: 'FAILED', child: Text('Thất bại')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatusFilter = val;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Card(
                color: AppColors.card,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredOrders.isEmpty
                        ? const Center(child: Text('Không tìm thấy đơn hàng nào'))
                        : DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 900,
                            columns: const [
                              DataColumn2(label: Text('Mã đơn hàng'), size: ColumnSize.L),
                              DataColumn2(label: Text('Khách hàng'), size: ColumnSize.L),
                              DataColumn2(label: Text('Số điện thoại'), size: ColumnSize.M),
                              DataColumn2(label: Text('Tỉnh thành'), size: ColumnSize.M),
                              DataColumn2(label: Text('Tổng tiền'), size: ColumnSize.M, numeric: true),
                              DataColumn2(label: Text('Trạng thái'), size: ColumnSize.M),
                              DataColumn2(label: Text('Hành động'), size: ColumnSize.L),
                            ],
                            rows: _filteredOrders.map((order) {
                              final isNew = order.status.toUpperCase() == 'NEW';
                              return DataRow(
                                cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showOrderDetails(order),
                                      child: Text(
                                        order.orderCode,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(order.customerName)),
                                  DataCell(Text(order.phone)),
                                  DataCell(Text(order.deliveryProvince)),
                                  DataCell(Text('${order.totalAmount.toStringAsFixed(0)} ₫')),
                                  DataCell(_statusBadge(order.status)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility_outlined),
                                          tooltip: 'Xem chi tiết',
                                          onPressed: () => _showOrderDetails(order),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: isNew ? AppColors.primary : Colors.grey.shade400,
                                          ),
                                          tooltip: isNew ? 'Chỉnh sửa đơn hàng' : 'Chỉ được sửa khi trạng thái Mới tạo',
                                          onPressed: isNew
                                              ? () async {
                                                  final updated = await showDialog<OrderModel>(
                                                    context: context,
                                                    builder: (context) => EditOrderDialog(order: order),
                                                  );
                                                  if (updated != null) {
                                                    _loadData();
                                                  }
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.cancel_outlined,
                                            color: isNew ? AppColors.danger : Colors.grey.shade400,
                                          ),
                                          tooltip: isNew ? 'Hủy đơn hàng' : 'Chỉ được hủy khi trạng thái Mới tạo',
                                          onPressed: isNew ? () => _cancelOrder(order) : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: value),
        ],
      ),
    );
  }
}
