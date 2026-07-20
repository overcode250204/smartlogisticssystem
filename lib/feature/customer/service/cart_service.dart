import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';

class CartItem {
  final int productId;
  final String productName;
  final String productCode;
  final String sku;
  final double price;
  final double? weight;
  final String? imageUrl;
  final String? baseUnitName;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.sku,
    required this.price,
    this.weight,
    this.imageUrl,
    this.baseUnitName,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
  double get totalWeight => (weight ?? 0) * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productCode': productCode,
    'sku': sku,
    'price': price,
    'weight': weight,
    'imageUrl': imageUrl,
    'baseUnitName': baseUnitName,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: (json['productId'] as num).toInt(),
    productName: json['productName'] as String,
    productCode: json['productCode'] as String,
    sku: json['sku'] as String,
    price: (json['price'] as num).toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    imageUrl: json['imageUrl'] as String?,
    baseUnitName: json['baseUnitName'] as String?,
    quantity: (json['quantity'] as num).toInt(),
  );

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    productName: productName,
    productCode: productCode,
    sku: sku,
    price: price,
    weight: weight,
    imageUrl: imageUrl,
    baseUnitName: baseUnitName,
    quantity: quantity ?? this.quantity,
  );
}

class CartService {
  static const String _cartKey = 'customer_cart';

  static CartService? _instance;
  static CartService get instance => _instance ??= CartService._();
  CartService._();

  List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalWeight => _items.fold(0, (sum, item) => sum + item.totalWeight);
  bool get isEmpty => _items.isEmpty;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      _items = list.map((e) => CartItem.fromJson(e)).toList();
    }
    _notificationCount = prefs.getInt('${_cartKey}_notification') ?? 0;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> addFromProduct(ProductResponse product, int quantity) async {
    final idx = _items.indexWhere((e) => e.productId == product.productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + quantity);
    } else {
      _items.add(CartItem(
        productId: product.productId,
        productName: product.productName,
        productCode: product.productCode,
        sku: product.sku,
        price: product.price,
        weight: product.weight,
        imageUrl: product.imageUrl,
        baseUnitName: product.baseUnitName,
        quantity: quantity,
      ));
    }
    _notificationCount += quantity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_cartKey}_notification', _notificationCount);
    await _save();
  }

  Future<void> markCartAsSeen() async {
    _notificationCount = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_cartKey}_notification', 0);
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await remove(productId);
      return;
    }
    final idx = _items.indexWhere((e) => e.productId == productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      await _save();
    }
  }

  Future<void> remove(int productId) async {
    _items.removeWhere((e) => e.productId == productId);
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
  }
}
