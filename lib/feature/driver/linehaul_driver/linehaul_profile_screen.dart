import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/feature/authentication/auth_service/auth_service.dart';

class LinehaulProfileScreen extends StatefulWidget {
  const LinehaulProfileScreen({super.key});

  @override
  State<LinehaulProfileScreen> createState() => _LinehaulProfileScreenState();
}

class _LinehaulProfileScreenState extends State<LinehaulProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _errorMessage = '';

  String _fullName = '';
  String _email = '';
  String _roleName = 'Tài xế Linehaul';

  // Driver details from API
  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      _fullName = prefs.getString('fullName') ?? 'Tài xế';
      _email = prefs.getString('email') ?? '';
      _roleName = prefs.getString('roleName') ?? 'Tài xế Linehaul';

      if (userId != null) {
        final response = await _apiClient.get('drivers/by-user/$userId');
        if (response.statusCode == 200 && response.data != null) {
          final resBody = response.data as Map<String, dynamic>;
          if (resBody['data'] != null) {
            setState(() {
              _driverData = resBody['data'] as Map<String, dynamic>;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải thông tin tài xế chi tiết';
      });
      print('Error loading driver profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = _driverData?['name'] ?? _fullName;
    final phone = _driverData?['phone'] ?? 'Chưa cập nhật';
    final status = _driverData?['status'] ?? 'AVAILABLE';
    final driverType = _driverData?['driverType'] ?? 'LINEHAUL';
    final vehicle = _driverData?['currentVehicle'];
    final warehouse = _driverData?['currentWarehouse'];
    final zone = _driverData?['zone'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hồ sơ tài xế', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _loadProfileData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _roleName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),

                  // Info Section 1: Contact
                  _buildSectionHeader('Thông tin liên hệ'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.email_outlined, 'Email', _email),
                    const Divider(height: 1),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', phone),
                  ]),
                  const SizedBox(height: 16),

                  // Info Section 2: Work Status
                  _buildSectionHeader('Trạng thái làm việc'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.info_outline,
                      'Trạng thái',
                      status == 'AVAILABLE'
                          ? 'Sẵn sàng (Available)'
                          : status == 'ON_LINEHAUL_TRIP'
                              ? 'Đang thực hiện chuyến đi'
                              : status,
                      valueColor: status == 'AVAILABLE' ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(Icons.merge_type, 'Loại tài xế', driverType),
                    if (zone != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(Icons.map_outlined, 'Khu vực hoạt động', zone['name'] ?? 'N/A'),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  // Info Section 3: Vehicle Info
                  _buildSectionHeader('Phương tiện đang sử dụng'),
                  _buildInfoCard([
                    if (vehicle != null) ...[
                      _buildInfoRow(Icons.directions_car_filled_outlined, 'Biển số xe', vehicle['licensePlate'] ?? 'N/A'),
                      const Divider(height: 1),
                      _buildInfoRow(Icons.local_shipping_outlined, 'Loại xe', vehicle['vehicleType']?.toString() ?? 'N/A'),
                      const Divider(height: 1),
                      _buildInfoRow(Icons.fitness_center, 'Tải trọng tối đa', '${vehicle['maxWeightKg'] ?? 0} kg'),
                      const Divider(height: 1),
                      _buildInfoRow(Icons.view_in_ar, 'Thể tích tối đa', '${vehicle['maxVolumeM3'] ?? 0} m³'),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Chưa được gán phương tiện nào',
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),

                  // Info Section 4: Current Warehouse
                  _buildSectionHeader('Kho hiện tại'),
                  _buildInfoCard([
                    if (warehouse != null) ...[
                      _buildInfoRow(Icons.warehouse_outlined, 'Tên kho', warehouse['name'] ?? 'N/A'),
                      const Divider(height: 1),
                      _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', warehouse['address'] ?? 'N/A'),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.warehouse_outlined, color: Colors.grey.shade400),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Không ở kho nào cố định',
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),

                  // Action Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _logout,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
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
