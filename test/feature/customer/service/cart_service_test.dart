import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/feature/customer/service/cart_service.dart';

void main() {
  late CartService cart;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'customer_cart': '[]',
      'customer_cart_notification': 0,
    });
    cart = CartService.instance;
    await cart.load();
  });

  ProductResponse product({
    int id = 1,
    String name = 'Rice',
    double price = 12000,
    double? weight = 2.5,
  }) {
    return ProductResponse(
      productId: id,
      productCode: 'P$id',
      productName: name,
      sku: 'SKU-$id',
      price: price,
      weight: weight,
      baseUnitName: 'bag',
    );
  }

  test('CartItem calculates totals and round trips through json', () {
    final item = CartItem(
      productId: 7,
      productName: 'Coffee',
      productCode: 'CF',
      sku: 'CF-001',
      price: 50000,
      weight: 0.5,
      quantity: 3,
      imageUrl: 'coffee.png',
      baseUnitName: 'box',
    );

    expect(item.subtotal, 150000);
    expect(item.totalWeight, 1.5);

    final decoded = CartItem.fromJson(item.toJson());
    expect(decoded.productId, item.productId);
    expect(decoded.quantity, 3);
    expect(decoded.copyWith(quantity: 5).quantity, 5);
  });

  test(
    'adds products, merges quantities, and persists notification count',
    () async {
      await cart.addFromProduct(product(), 2);
      await cart.addFromProduct(product(), 3);

      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 5);
      expect(cart.totalCount, 5);
      expect(cart.totalAmount, 60000);
      expect(cart.totalWeight, 12.5);
      expect(cart.notificationCount, 5);

      final reloaded = CartService.instance;
      await reloaded.load();
      expect(reloaded.items.single.quantity, 5);
      expect(reloaded.notificationCount, 5);
    },
  );

  test('updates, removes, clears, and marks notifications as seen', () async {
    await cart.addFromProduct(product(), 2);
    await cart.addFromProduct(product(id: 2, name: 'Milk', price: 10000), 1);

    await cart.updateQuantity(1, 4);
    expect(cart.items.firstWhere((item) => item.productId == 1).quantity, 4);

    await cart.updateQuantity(2, 0);
    expect(cart.items.any((item) => item.productId == 2), isFalse);

    await cart.markCartAsSeen();
    expect(cart.notificationCount, 0);

    await cart.clear();
    expect(cart.isEmpty, isTrue);
  });
}
