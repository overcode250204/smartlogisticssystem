import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/data/model/customer_address_model.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_address_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/customer_order_service.dart';
import 'package:smartlogisticssystem/feature/customer/service/location_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _paymentType = 'COD';
  Province? _selectedProvince;
  bool _submitting = false;

  final _cart = CartService.instance;
  final _orderService = CustomerOrderService();
  final _addressService = CustomerAddressService();
  final _locationService = LocationService();

  List<Province> _provinces = [];
  List<CustomerAddressModel> _savedAddresses = [];
  CustomerAddressModel? _selectedAddress;
  bool _loadingProvinces = true;
  bool _loadingAddresses = true;
  bool _savingAddress = false;
  bool _saveAddressForNextTime = true;
  bool _saveAsDefaultAddress = true;
  String? _provinceError;
  String? _addressError;

  static const _supportedPaymentTypes = {'COD', 'CREDIT'};

  // Map and Location states
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(
    10.7769,
    106.7009,
  ); // Default to HCMC center initially if not found
  bool _isGettingLocation = false;
  bool _hasChosenLocation = false;
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
    _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    await _fetchProvinces();
    await _loadAddresses();
  }

  Future<void> _fetchProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _provinceError = null;
    });
    try {
      final data = await _locationService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = data;
          _loadingProvinces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _provinceError = e.toString();
          _loadingProvinces = false;
        });
      }
    }
  }

  Future<void> _prefillUserInfo() async {
    await _cart.load();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('fullName') ?? '';
        _phoneController.text = prefs.getString('phone') ?? '';
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });
    try {
      final addresses = await _addressService.getAddresses();
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        _loadingAddresses = false;
      });
      final defaultAddress = addresses
          .where((address) => address.isDefault)
          .firstOrNull;
      final addressToUse =
          defaultAddress ?? (addresses.isNotEmpty ? addresses.first : null);
      if (addressToUse != null) {
        _applyAddress(addressToUse);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAddresses = false;
        _addressError = apiErrorMessage(e);
      });
    }
  }

  void _applyAddress(CustomerAddressModel address) {
    final province = _provinces.where((p) {
      return p.code == address.provinceCode ||
          LocationService.normalizeProvinceName(p.name) ==
              LocationService.normalizeProvinceName(address.provinceName);
    }).firstOrNull;
    final point = LatLng(address.latitude, address.longitude);
    setState(() {
      _selectedAddress = address;
      _nameController.text = address.receiverName;
      _phoneController.text = address.phone;
      _addressController.text = address.deliveryAddress;
      _selectedProvince =
          province ??
          Province(code: address.provinceCode, name: address.provinceName);
      _selectedLocation = point;
      _hasChosenLocation = true;
      _saveAddressForNextTime = false;
    });
    _mapController.move(point, 15);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatus = 'Đang lấy vị trí hiện tại...';
    });
    try {
      final pos = await _locationService.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15);
      await _handleLocationPicked(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể lấy vị trí: $e. Vui lòng chọn trên bản đồ.',
            ),
            backgroundColor: CustomerColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _locationStatus = '';
        });
      }
    }
  }

  Future<void> _handleLocationPicked(LatLng latLng) async {
    setState(() {
      _selectedAddress = null;
      _selectedLocation = latLng;
      _hasChosenLocation = true;
      _locationStatus = 'Đang xác định địa chỉ...';
    });

    final res = await _locationService.reverseGeocode(
      latLng.latitude,
      latLng.longitude,
    );

    if (!mounted) return;

    setState(() => _locationStatus = '');

    if (res.isNotEmpty) {
      // Update address if it's currently empty, or we want to overwrite
      if (_addressController.text.trim().isEmpty ||
          res['display_name'] != null) {
        _addressController.text =
            res['display_name'] ?? _addressController.text;
      }

      // Try to match province
      if (res['province'] != null && _provinces.isNotEmpty) {
        final normalizedGeo = LocationService.normalizeProvinceName(
          res['province'],
        );
        final match = _provinces.where((p) {
          final normalizedP = LocationService.normalizeProvinceName(p.name);
          return normalizedGeo.contains(normalizedP) ||
              normalizedP.contains(normalizedGeo);
        }).firstOrNull;

        if (match != null) {
          setState(() {
            _selectedAddress = null;
            _selectedProvince = match;
          });
        } else if (_selectedProvince != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vị trí trên bản đồ có thể không thuộc tỉnh/thành phố đã chọn. Vui lòng kiểm tra lại.',
              ),
              backgroundColor: CustomerColors.warning,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final paymentType = _supportedPaymentTypes.contains(_paymentType)
        ? _paymentType
        : 'COD';
    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Tỉnh/Thành phố!'),
          backgroundColor: CustomerColors.danger,
        ),
      );
      return;
    }
    if (!_hasChosenLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí giao hàng trên bản đồ.'),
          backgroundColor: CustomerColors.danger,
        ),
      );
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng trống!'),
          backgroundColor: CustomerColors.danger,
        ),
      );
      return;
    }
    if (_selectedLocation.latitude < -90 ||
        _selectedLocation.latitude > 90 ||
        _selectedLocation.longitude < -180 ||
        _selectedLocation.longitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tọa độ giao hàng không hợp lệ.'),
          backgroundColor: CustomerColors.danger,
        ),
      );
      return;
    }

    final itemQuantities = <int, int>{};
    for (final item in _cart.items) {
      if (item.productId <= 0 || item.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm trong giỏ hàng không hợp lệ.'),
            backgroundColor: CustomerColors.danger,
          ),
        );
        return;
      }
      itemQuantities[item.productId] =
          (itemQuantities[item.productId] ?? 0) + item.quantity;
    }

    setState(() => _submitting = true);
    try {
      if (_selectedAddress == null && _saveAddressForNextTime) {
        final savedAddress = await _addressService.createAddress(
          _currentAddressRequest(isDefault: _saveAsDefaultAddress),
        );
        if (mounted) {
          setState(() {
            _selectedAddress = savedAddress;
            _savedAddresses = [
              savedAddress,
              ..._savedAddresses.where(
                (address) => address.addressId != savedAddress.addressId,
              ),
            ];
          });
        }
      }

      final request = OrderCreateRequest(
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        deliveryProvince: _selectedProvince!.name,
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        paymentType: paymentType,
        items: itemQuantities.entries
            .map((e) => OrderItemRequest(productId: e.key, quantity: e.value))
            .toList(),
      );

      final order = await _orderService.createOrder(request);
      await _cart.clear();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CustomerColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: CustomerColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã đơn hàng: ${order.orderCode}',
                  style: const TextStyle(color: CustomerColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/customer/orders');
                },
                child: const Text('Xem đơn hàng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/customer');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: CustomerColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  CustomerAddressRequest _currentAddressRequest({required bool isDefault}) {
    return CustomerAddressRequest(
      receiverName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      provinceCode: _selectedProvince!.code,
      provinceName: _selectedProvince!.name,
      deliveryAddress: _addressController.text.trim(),
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      isDefault: isDefault,
      label: _selectedAddress?.label ?? 'Nhà riêng',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final items = _cart.items;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/customer/cart'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Giỏ hàng'),
                style: TextButton.styleFrom(
                  foregroundColor: CustomerColors.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: CustomerColors.textSecondary,
              ),
              const Text(
                'Đặt hàng',
                style: TextStyle(
                  color: CustomerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildForm()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildSummary(formatter, items)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildForm(),
                  const SizedBox(height: 16),
                  _buildSummary(formatter, items),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return CustomerCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CustomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAddressSection(),
            const SizedBox(height: 16),
            _formField(
              _nameController,
              'Họ và tên *',
              Icons.person_outline,
              required: true,
            ),
            const SizedBox(height: 12),
            _formField(
              _phoneController,
              'Số điện thoại *',
              Icons.phone_outlined,
              required: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Trường này là bắt buộc';
                final normalized = phone.replaceAll(RegExp(r'[\s.-]'), '');
                if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(normalized)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            _buildProvinceSelector(),
            const SizedBox(height: 12),

            _formField(
              _addressController,
              'Địa chỉ giao hàng chi tiết *',
              Icons.location_on_outlined,
              required: true,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Map picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vị trí giao hàng trên bản đồ *',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CustomerColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: const Text(
                    'Sử dụng vị trí hiện tại',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 320,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasChosenLocation
                      ? CustomerColors.border
                      : CustomerColors.danger,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) => _handleLocationPicked(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartlogistics.app',
                    ),
                    if (_hasChosenLocation)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: CustomerColors.danger,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (_locationStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CustomerColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _locationStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CustomerColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (_hasChosenLocation)
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed,
                    size: 14,
                    color: CustomerColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vĩ độ: ${_selectedLocation.latitude.toStringAsFixed(6)} • Kinh độ: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CustomerColors.textSecondary,
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Vui lòng chọn vị trí trên bản đồ',
                style: TextStyle(color: CustomerColors.danger, fontSize: 12),
              ),
            const SizedBox(height: 16),
            const Divider(color: CustomerColors.border),
            const SizedBox(height: 16),

            // Payment
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: CustomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              label: 'COD - Thanh toán khi nhận hàng',
              icon: Icons.local_shipping_outlined,
              value: 'COD',
              groupValue: _paymentType,
              onChanged: (v) => setState(() => _paymentType = v!),
            ),
            _PaymentOption(
              label: 'Thẻ tín dụng / chuyển khoản',
              icon: Icons.account_balance_outlined,
              value: 'CREDIT',
              groupValue: _paymentType,
              onChanged: (v) => setState(() => _paymentType = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_loadingAddresses) {
      return const _AddressInfoBox(
        icon: Icons.hourglass_empty,
        text: 'Đang tải địa chỉ giao hàng...',
      );
    }
    if (_addressError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CustomerColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CustomerColors.warning),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: CustomerColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Không thể tải danh sách địa chỉ. Bạn vẫn có thể nhập thủ công.',
                style: const TextStyle(color: CustomerColors.textPrimary),
              ),
            ),
            TextButton(onPressed: _loadAddresses, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final address = _selectedAddress;
    if (address == null && _savedAddresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AddressInfoBox(
            icon: Icons.add_location_alt_outlined,
            text:
                'Bạn chưa lưu địa chỉ giao hàng nào. Nhập địa chỉ bên dưới để đặt hàng.',
          ),
          CheckboxListTile(
            value: _saveAddressForNextTime,
            onChanged: (value) =>
                setState(() => _saveAddressForNextTime = value ?? true),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Lưu địa chỉ này cho lần đặt hàng sau'),
          ),
          if (_saveAddressForNextTime)
            CheckboxListTile(
              value: _saveAsDefaultAddress,
              onChanged: (value) =>
                  setState(() => _saveAsDefaultAddress = value ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Đặt làm địa chỉ mặc định'),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: CustomerColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address == null
                      ? 'Địa chỉ giao hàng'
                      : '${address.label}${address.isDefault ? ' · Mặc định' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomerColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showAddressPicker,
                child: const Text('Thay đổi'),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 6),
            Text(
              '${address.receiverName} · ${address.phone}',
              style: const TextStyle(color: CustomerColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              address.deliveryAddress,
              style: const TextStyle(color: CustomerColors.textSecondary),
            ),
            Text(
              address.provinceName,
              style: const TextStyle(color: CustomerColors.textSecondary),
            ),
          ] else
            const Text(
              'Bạn đang nhập địa chỉ mới thủ công.',
              style: TextStyle(color: CustomerColors.textSecondary),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddressForm(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm địa chỉ'),
              ),
              if (address != null)
                OutlinedButton.icon(
                  onPressed: () => _showAddressForm(address: address),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Chỉnh sửa'),
                ),
            ],
          ),
          if (address == null)
            CheckboxListTile(
              value: _saveAddressForNextTime,
              onChanged: (value) =>
                  setState(() => _saveAddressForNextTime = value ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Lưu địa chỉ này cho lần đặt hàng sau'),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddressPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn địa chỉ giao hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _savedAddresses.length,
                  separatorBuilder: (_, index) => const Divider(),
                  itemBuilder: (_, index) {
                    final address = _savedAddresses[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${address.label}${address.isDefault ? ' · Mặc định' : ''}',
                      ),
                      subtitle: Text(
                        '${address.receiverName} · ${address.phone}\n${address.deliveryAddress}\n${address.provinceName}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            tooltip: 'Chọn',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _applyAddress(address);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Sửa',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddressForm(address: address);
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Mặc định',
                            onPressed: () async {
                              await _setDefaultAddress(address);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.star_border),
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () async {
                              await _deleteAddress(address);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: CustomerColors.danger,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddressForm();
                  },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Thêm địa chỉ mới'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddressForm({CustomerAddressModel? address}) async {
    final labelController = TextEditingController(
      text: address?.label ?? 'Nhà riêng',
    );
    final nameController = TextEditingController(
      text: address?.receiverName ?? _nameController.text,
    );
    final phoneController = TextEditingController(
      text: address?.phone ?? _phoneController.text,
    );
    final detailController = TextEditingController(
      text: address?.deliveryAddress ?? _addressController.text,
    );
    Province? province = address == null
        ? _selectedProvince
        : _provinces.where((p) => p.code == address.provinceCode).firstOrNull ??
              Province(code: address.provinceCode, name: address.provinceName);
    LatLng point = address == null
        ? _selectedLocation
        : LatLng(address.latitude, address.longitude);
    bool hasPoint = address != null || _hasChosenLocation;
    bool isDefault = address?.isDefault ?? _saveAsDefaultAddress;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address == null ? 'Thêm địa chỉ mới' : 'Chỉnh sửa địa chỉ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Nhãn địa chỉ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên người nhận *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Province>(
                    initialValue: province,
                    decoration: const InputDecoration(
                      labelText: 'Tỉnh/Thành phố *',
                    ),
                    isExpanded: true,
                    items: _provinces
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.name)),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() => province = value),
                    validator: (v) => v == null ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ chi tiết *',
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 13,
                          onTap: (_, tappedPoint) => setSheetState(() {
                            point = tappedPoint;
                            hasPoint = true;
                          }),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.smartlogistics.app',
                          ),
                          if (hasPoint)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: CustomerColors.danger,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (value) =>
                        setSheetState(() => isDefault = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Đặt làm địa chỉ mặc định'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savingAddress
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (!hasPoint) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng chọn vị trí trên bản đồ.',
                                    ),
                                    backgroundColor: CustomerColors.danger,
                                  ),
                                );
                                return;
                              }
                              await _saveAddressFromForm(
                                existing: address,
                                request: CustomerAddressRequest(
                                  receiverName: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  provinceCode: province!.code,
                                  provinceName: province!.name,
                                  deliveryAddress: detailController.text.trim(),
                                  latitude: point.latitude,
                                  longitude: point.longitude,
                                  isDefault: isDefault,
                                  label: labelController.text.trim().isEmpty
                                      ? 'Nhà riêng'
                                      : labelController.text.trim(),
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Lưu địa chỉ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    labelController.dispose();
    nameController.dispose();
    phoneController.dispose();
    detailController.dispose();
  }

  Future<void> _saveAddressFromForm({
    required CustomerAddressModel? existing,
    required CustomerAddressRequest request,
  }) async {
    setState(() => _savingAddress = true);
    try {
      final saved = existing == null
          ? await _addressService.createAddress(request)
          : await _addressService.updateAddress(existing.addressId, request);
      final addresses = await _addressService.getAddresses();
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
      });
      _applyAddress(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: CustomerColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAddress = false);
    }
  }

  Future<void> _setDefaultAddress(CustomerAddressModel address) async {
    try {
      final saved = await _addressService.setDefaultAddress(address.addressId);
      await _loadAddresses();
      _applyAddress(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: CustomerColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(CustomerAddressModel address) async {
    try {
      await _addressService.deleteAddress(address.addressId);
      await _loadAddresses();
      if (_selectedAddress?.addressId == address.addressId && mounted) {
        setState(() => _selectedAddress = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: CustomerColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildProvinceSelector() {
    if (_loadingProvinces) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CustomerColors.border),
          color: CustomerColors.surfaceSecondary,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Đang tải danh sách tỉnh...',
              style: TextStyle(color: CustomerColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_provinceError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CustomerColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CustomerColors.danger),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: CustomerColors.danger,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _provinceError!,
                style: const TextStyle(
                  color: CustomerColors.danger,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _fetchProvinces,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Province>(
      initialValue: _selectedProvince,
      decoration: InputDecoration(
        labelText: 'Tỉnh/Thành phố *',
        prefixIcon: const Icon(Icons.map_outlined, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      isExpanded: true,
      hint: const Text('Chọn Tỉnh/Thành phố'),
      items: _provinces
          .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _selectedAddress = null;
            _selectedProvince = v;
          });
        }
      },
      validator: (v) => v == null ? 'Vui lòng chọn Tỉnh/Thành phố' : null,
    );
  }

  Widget _buildSummary(NumberFormat formatter, List<CartItem> items) {
    return CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn hàng của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: CustomerColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            color: CustomerColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatter.format(item.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: CustomerColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: CustomerColors.border),
          _SummaryLine(
            'Tổng trọng lượng',
            '${_cart.totalWeight.toStringAsFixed(2)} kg',
          ),
          _SummaryLine(
            'Tổng tiền hàng',
            formatter.format(_cart.totalAmount),
            bold: true,
            color: CustomerColors.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận đặt hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomerColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CustomerColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      validator:
          validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Trường này là bắt buộc'
                    : null
              : null),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CustomerColors.primary.withValues(alpha: 0.06)
              : CustomerColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? CustomerColors.primary : CustomerColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? CustomerColors.primary
                  : CustomerColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? CustomerColors.primary
                      : CustomerColors.textPrimary,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: CustomerColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _SummaryLine(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: CustomerColors.textSecondary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? CustomerColors.textPrimary,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AddressInfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomerColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: CustomerColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: CustomerColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
