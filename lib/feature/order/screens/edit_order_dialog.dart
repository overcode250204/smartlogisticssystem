import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/order/service/order_service.dart';
import 'package:smartlogisticssystem/feature/product/product_service/product_service.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:dio/dio.dart';

class EditOrderDialog extends StatefulWidget {
  final OrderModel order;

  const EditOrderDialog({super.key, required this.order});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _OrderItemTemp {
  int productId;
  String productName;
  int quantity;
  double price;

  _OrderItemTemp({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  List<ProductResponse> _products = [];
  List<String> _provinces = [];
  List<_OrderItemTemp> _selectedItems = [];

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? _selectedProvince;
  String _selectedPaymentType = 'COD';

  @override
  void initState() {
    super.initState();
    _customerNameController.text = widget.order.customerName;
    _phoneController.text = widget.order.phone;
    _deliveryAddressController.text = widget.order.deliveryAddress;
    _latitudeController.text = widget.order.latitude.toString();
    _longitudeController.text = widget.order.longitude.toString();
    _selectedProvince = widget.order.deliveryProvince;
    _selectedPaymentType = widget.order.paymentType;

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await _productService.getAllProducts();
      List<String> provinces = [];
      try {
        final dio = Dio();
        final response = await dio.get('https://provinces.open-api.vn/api/v2/p/');
        if (response.statusCode == 200 && response.data is List) {
          provinces = (response.data as List)
              .map((p) => p['name'] as String)
              .toList();
        }
      } catch (e) {
        print('Error loading provinces: $e');
        // Fallback with some default provinces
        provinces = [
          'Thành phố Hà Nội',
          'Thành phố Hồ Chí Minh',
          'Thành phố Đà Nẵng',
          'Tỉnh Bình Dương',
          'Tỉnh Đồng Nai',
        ];
      }

      // Populate selected items from order
      final itemsTemp = <_OrderItemTemp>[];
      for (var item in widget.order.items) {
        // Try to match product by name to get ID, or fallback
        final matchedProd = products.firstWhere(
          (p) => p.productName == item.productName,
          orElse: () => ProductResponse(
            productId: 0,
            productName: item.productName,
            productCode: '',
            sku: '',
            price: item.unitPrice,
          ),
        );
        if (matchedProd.productId != 0) {
          itemsTemp.add(_OrderItemTemp(
            productId: matchedProd.productId,
            productName: item.productName,
            quantity: item.quantityOrdered,
            price: item.unitPrice,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _products = products;
          _provinces = provinces;
          _selectedItems = itemsTemp;
          // Ensure original province is in options
          if (_selectedProvince != null && !provinces.contains(_selectedProvince)) {
            _provinces.insert(0, _selectedProvince!);
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu sản phẩm hoặc tỉnh thành: ${apiErrorMessage(e)}';
          _isLoadingData = false;
        });
      }
    }
  }

  void _addItem() {
    if (_products.isEmpty) return;
    
    // Find first product that is not already added
    ProductResponse? availableProduct;
    for (var p in _products) {
      if (!_selectedItems.any((item) => item.productId == p.productId)) {
        availableProduct = p;
        break;
      }
    }

    availableProduct ??= _products.first;

    setState(() {
      _selectedItems.add(_OrderItemTemp(
        productId: availableProduct!.productId,
        productName: availableProduct.productName,
        quantity: 1,
        price: availableProduct.price,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  double get _totalAmount {
    return _selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn Tỉnh/Thành phố';
      });
      return;
    }
    if (_selectedItems.isEmpty) {
      setState(() {
        _errorMessage = 'Đơn hàng phải có ít nhất một sản phẩm';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = OrderCreateRequest(
        customerName: _customerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryAddress: _deliveryAddressController.text.trim(),
        deliveryProvince: _selectedProvince!,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        paymentType: _selectedPaymentType,
        items: _selectedItems
            .map((e) => OrderItemRequest(productId: e.productId, quantity: e.quantity))
            .toList(),
      );

      final updatedOrder = await _orderService.updateOrder(widget.order.orderId, request);
      if (mounted) {
        Navigator.pop(context, updatedOrder);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = apiErrorMessage(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chỉnh sửa đơn hàng: ${widget.order.orderCode}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
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
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Information
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              // padding: const EdgeInsets.ri: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thông tin khách hàng & Giao nhận',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _customerNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tên khách hàng *',
                                      hintText: 'Nhập tên khách hàng',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Vui lòng nhập tên khách hàng'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Số điện thoại *',
                                      hintText: 'Nhập số điện thoại',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Vui lòng nhập số điện thoại'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _deliveryAddressController,
                                    decoration: const InputDecoration(
                                      labelText: 'Địa chỉ giao hàng *',
                                      hintText: 'Nhập địa chỉ chi tiết',
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Vui lòng nhập địa chỉ giao hàng'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedProvince,
                                    decoration: const InputDecoration(
                                      labelText: 'Tỉnh/Thành phố *',
                                    ),
                                    items: _provinces
                                        .map((p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(p),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedProvince = val;
                                      });
                                    },
                                    validator: (value) => value == null
                                        ? 'Vui lòng chọn Tỉnh/Thành phố'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _latitudeController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Vĩ độ (Latitude) *',
                                          ),
                                          validator: (value) => value == null || double.tryParse(value) == null
                                              ? 'Vĩ độ không hợp lệ'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _longitudeController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Kinh độ (Longitude) *',
                                          ),
                                          validator: (value) => value == null || double.tryParse(value) == null
                                              ? 'Kinh độ không hợp lệ'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPaymentType,
                                    decoration: const InputDecoration(
                                      labelText: 'Phương thức thanh toán *',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'COD', child: Text('COD (Thanh toán khi nhận hàng)')),
                                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản ngân hàng')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedPaymentType = val ?? 'COD';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 24, color: AppColors.border),
                          // Right side - Items list
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Danh sách sản phẩm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _addItem,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Thêm sản phẩm'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _selectedItems.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Chưa chọn sản phẩm nào',
                                            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _selectedItems.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final item = _selectedItems[index];
                                            return Card(
                                              color: Colors.grey.shade50,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                side: const BorderSide(color: AppColors.border),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: DropdownButtonHideUnderline(
                                                        child: DropdownButton<int>(
                                                          isExpanded: true,
                                                          value: item.productId,
                                                          items: _products
                                                              .map((p) => DropdownMenuItem(
                                                                    value: p.productId,
                                                                    child: Text(
                                                                      p.productName,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ))
                                                              .toList(),
                                                          onChanged: (val) {
                                                            if (val == null) return;
                                                            final prod = _products.firstWhere((p) => p.productId == val);
                                                            setState(() {
                                                              item.productId = prod.productId;
                                                              item.productName = prod.productName;
                                                              item.price = prod.price;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 80,
                                                      child: TextFormField(
                                                        initialValue: item.quantity.toString(),
                                                        keyboardType: TextInputType.number,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          labelText: 'SL',
                                                        ),
                                                        onChanged: (val) {
                                                          final qty = int.tryParse(val) ?? 1;
                                                          setState(() {
                                                            item.quantity = qty < 1 ? 1 : qty;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      onPressed: () => _removeItem(index),
                                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const Divider(height: 24, color: AppColors.border),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tổng tiền ước tính:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '${_totalAmount.toStringAsFixed(0)} ₫',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Cập nhật'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
