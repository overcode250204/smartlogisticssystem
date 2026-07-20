import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/networking.dart';

class LinehaulHistoryScreen extends StatefulWidget {
  const LinehaulHistoryScreen({super.key});

  @override
  State<LinehaulHistoryScreen> createState() => _LinehaulHistoryScreenState();
}

class _LinehaulHistoryScreenState extends State<LinehaulHistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _trips = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiClient.get(
        'linehaul-trip',
        queryParameters: {'status': 'ARRIVED'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resBody = response.data as Map<String, dynamic>;
        setState(() {
          _trips = resBody['data'] as List<dynamic>? ?? [];
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử chuyến đi';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ';
      });
      print('Error fetching history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lịch sử chuyến đi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có chuyến đi nào hoàn thành',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          final code = trip['linehaulTripCode'] ?? 'N/A';
                          final route = trip['routeConfig'];
                          final fromWh = route?['fromWarehouse']?['name'] ?? 'N/A';
                          final toWh = route?['toWarehouse']?['name'] ?? 'N/A';
                          final vehicle = trip['vehicle']?['licensePlate'] ?? 'N/A';
                          final depTime = _formatDateTime(trip['departureTime']);
                          final arrTime = _formatDateTime(trip['arrivalTime']);
                          final palletsCount = (trip['pallets'] as List<dynamic>?)?.length ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Hoàn thành',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // From / To Route UI
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              Icon(Icons.radio_button_checked, color: Colors.blue.shade700, size: 18),
                                              Container(
                                                width: 2,
                                                height: 30,
                                                color: Colors.grey.shade300,
                                              ),
                                              Icon(Icons.location_on, color: Colors.red.shade700, size: 18),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Từ: $fromWh',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  'Đến: $toWh',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),

                                      // Time and vehicle info
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildMetaCol('Xe vận tải', vehicle, Icons.local_shipping_outlined),
                                          _buildMetaCol('Số pallet', '$palletsCount Pallets', Icons.inventory_2_outlined),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildMetaCol('Giờ khởi hành', depTime, Icons.play_circle_outline),
                                          _buildMetaCol('Giờ hoàn thành', arrTime, Icons.check_circle_outline),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildMetaCol(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
