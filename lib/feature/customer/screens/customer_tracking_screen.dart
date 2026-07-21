import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/order_tracking_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_order_service.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final int orderId;
  const CustomerTrackingScreen({super.key, required this.orderId});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  final _orderService = CustomerOrderService();

  OrderModel? _order;
  List<OrderTrackingModel> _tracking = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final order = await _orderService.getMyOrderById(widget.orderId);
      final tracking = await _orderService.getMyOrderTracking(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _tracking = tracking;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Không thể tải dữ liệu theo dõi: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: CustomerColors.primary));
    if (_error.isNotEmpty) return CustomerErrorState(message: _error, onRetry: _load);
    if (_order == null) return const SizedBox();

    final order = _order!;
    final hasTracking = _tracking.isNotEmpty;

    // Build map data
    final trackingPoints = _tracking
        .map((t) => LatLng(t.latitude, t.longitude))
        .toList();

    // Center: last tracking point, or order delivery coordinates
    final center = hasTracking
        ? trackingPoints.last
        : LatLng(order.latitude, order.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: CustomerColors.surface,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/customer/orders/${order.orderId}'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Chi tiết đơn'),
                style: TextButton.styleFrom(foregroundColor: CustomerColors.primary, padding: EdgeInsets.zero),
              ),
              const Spacer(),
              CustomerStatusBadge(status: order.status),
            ],
          ),
        ),
        const Divider(height: 1, color: CustomerColors.border),

        Expanded(
          child: LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 2, child: _buildMap(center, trackingPoints, order)),
                  SizedBox(width: 340, child: _buildPanel(order)),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.45, child: _buildMap(center, trackingPoints, order)),
                Expanded(child: _buildPanel(order)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMap(LatLng center, List<LatLng> points, OrderModel order) {
    final destPoint = LatLng(order.latitude, order.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: points.length > 1 ? 12.0 : 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartlogistics.app',
        ),
        // Route polyline
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4,
                color: CustomerColors.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Tracking waypoints
            ...points.asMap().entries.map((e) {
              final isLast = e.key == points.length - 1;
              return Marker(
                point: e.value,
                width: isLast ? 36 : 16,
                height: isLast ? 36 : 16,
                child: isLast
                    ? Container(
                        decoration: BoxDecoration(
                          color: CustomerColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: CustomerColors.accent.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
              );
            }),
            // Destination marker
            Marker(
              point: destPoint,
              width: 36,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: CustomerColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
                ),
                child: const Icon(Icons.home, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel(OrderModel order) {
    return Container(
      color: CustomerColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CustomerColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: CustomerColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.deliveryAddress, style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                ]),
                if (order.expectedDeliveryTime != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule_outlined, size: 14, color: CustomerColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Dự kiến: ${_formatDate(order.expectedDeliveryTime!)}',
                      style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: CustomerColors.border),

          // Tracking timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử di chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: CustomerColors.textPrimary)),
                Text('${_tracking.length} điểm', style: const TextStyle(color: CustomerColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),

          Expanded(
            child: _tracking.isEmpty
                ? const CustomerEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Chưa có dữ liệu theo dõi',
                    subtitle: 'Vị trí sẽ được cập nhật khi đơn hàng được vận chuyển',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _tracking.length,
                    itemBuilder: (ctx, idx) {
                      final point = _tracking[_tracking.length - 1 - idx]; // newest first
                      final isLatest = idx == 0;
                      return _TrackingPoint(
                        tracking: point,
                        isLatest: isLatest,
                        isLast: idx == _tracking.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _TrackingPoint extends StatelessWidget {
  final OrderTrackingModel tracking;
  final bool isLatest;
  final bool isLast;

  const _TrackingPoint({required this.tracking, required this.isLatest, required this.isLast});

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    try {
      dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tracking.recordedAt));
    } catch (_) {
      dateStr = tracking.recordedAt;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLatest ? CustomerColors.primary : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isLatest ? const [BoxShadow(color: Color(0x331E40AF), blurRadius: 4)] : null,
              ),
            ),
            if (!isLast) Container(width: 2, height: 40, color: const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 12, color: CustomerColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text('${tracking.latitude.toStringAsFixed(5)}, ${tracking.longitude.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 12, fontWeight: isLatest ? FontWeight.bold : FontWeight.normal, color: isLatest ? CustomerColors.primary : CustomerColors.textPrimary))),
                  ],
                ),
                if (tracking.note != null && tracking.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tracking.note!, style: const TextStyle(fontSize: 12, color: CustomerColors.textSecondary)),
                ],
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: CustomerColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
