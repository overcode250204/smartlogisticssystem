import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/data/model/customer_address_model.dart';
import 'package:smartlogisticssystem/data/model/driver_model.dart';
import 'package:smartlogisticssystem/data/model/exception_reason_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_request_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_status.dart';
import 'package:smartlogisticssystem/data/model/inventory_request_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_request_model.dart';
import 'package:smartlogisticssystem/data/model/inventory_transaction_response_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_driver_model.dart';
import 'package:smartlogisticssystem/data/model/linehaul_trip_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_detail_model.dart';
import 'package:smartlogisticssystem/data/model/local_trip_model.dart';
import 'package:smartlogisticssystem/data/model/notification_model.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/order_tracking_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/route_config_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_request_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';
import 'package:smartlogisticssystem/data/model/unit_response.dart';
import 'package:smartlogisticssystem/data/model/user_model.dart';
import 'package:smartlogisticssystem/data/model/vehicle_model.dart';
import 'package:smartlogisticssystem/data/model/warehouse_model.dart';
import 'package:smartlogisticssystem/data/model/zone_model.dart';

void main() {
  group('request models', () {
    test('serializes create and sparse update requests', () {
      expect(
        ProductCreateRequest(
          productName: '  Milk ',
          sku: '  SKU-1 ',
          price: 10,
          weight: 1.5,
          length: 2,
          width: 3,
          height: 4,
          baseUnitId: 9,
          minStockLevel: 5,
          supplierId: 6,
          categoryId: 7,
        ).toJson(),
        containsPair('productName', 'Milk'),
      );
      expect(ProductUpdateRequest(productName: ' Tea ', sku: '').toJson(), {
        'productName': 'Tea',
        'sku': '',
      });
      expect(InventoryUpdateRequest(quantity: 20).toJson(), {'quantity': 20});
      expect(InventoryTransactionUpdateRequest(type: 'EXPORT').toJson(), {
        'type': 'EXPORT',
      });
      expect(SupplierUpdateRequest(address: 'HN').toJson(), {'address': 'HN'});
    });

    test('serializes warehouse, route, vehicle, zone, and batch requests', () {
      final now = DateTime.utc(2026, 1, 2, 3, 4, 5);

      expect(
        WarehouseCreateRequest(
          name: 'Hub A',
          type: WarehouseType.HUB,
          address: 'A',
          province: 'HN',
          latitude: 1,
          longitude: 2,
        ).toJson(),
        containsPair('type', 'HUB'),
      );
      expect(
        VehicleUpdateRequest(
          licensePlate: '51A',
          vehicleType: VehicleType.SMALL_TRUCK,
          maxWeightKg: 1000,
          maxVolumeM3: 8,
          status: VehicleStatus.ACTIVE,
        ).toJson(),
        containsPair('status', 'ACTIVE'),
      );
      expect(
        RouteConfigCreateRequest(
          routeName: 'R1',
          fromWarehouseId: 1,
          toWarehouseId: 2,
          dispatchType: DispatchType.HYBRID,
          cutoffTime: '08:00',
          provinceNames: const ['HN'],
          isActive: true,
        ).toJson(),
        containsPair('dispatchType', 'HYBRID'),
      );
      expect(
        ZoneCreateRequest(
          name: 'Z1',
          coverageArea: const {'type': 'Polygon'},
        ).toJson(),
        containsPair('name', 'Z1'),
      );
      expect(
        InventoryBatchCreateRequest(
          productId: 1,
          importDate: now,
          expirationDate: now,
          quantity: 10,
          remainingQuantity: 9,
          received: true,
        ).toJson(),
        containsPair('received', true),
      );
      expect(
        InventoryBatchUpdateRequest(
          status: InventoryBatchStatus.LOW_STOCK,
        ).toJson(),
        {'status': 'LOW_STOCK'},
      );
    });
  });

  group('response models', () {
    test('parses product page with nested supplier category and unit data', () {
      final page = ProductPageResponse.fromJson({
        'content': [
          {
            'productId': 1,
            'supplier': {'supplierId': 2, 'supplierName': 'Supplier'},
            'productCode': 'P001',
            'productName': 'Milk',
            'sku': 'SKU',
            'category': {'categoryId': 3, 'categoryName': 'Food'},
            'baseUnit': {'id': 4, 'code': 'BOX', 'name': 'Box'},
            'price': 12.5,
            'weight': 1,
          },
        ],
        'page': 1,
        'size': 20,
        'totalElements': 30,
        'totalPages': 2,
        'first': false,
        'last': true,
      });

      expect(page.content.single.supplier!.supplierId, 2);
      expect(page.content.single.categoryId, 3);
      expect(page.content.single.baseUnitCode, 'BOX');
      expect(page.last, isTrue);
    });

    test(
      'parses inventory batch variants with numeric strings and statuses',
      () {
        final batch = InventoryBatchResponse.fromJson({
          'batchId': 10,
          'product': {
            'productId': 1,
            'productName': 'Milk',
            'productCode': 'P1',
          },
          'requestedQuantity': '12',
          'exportedQuantity': 2.8,
          'importDate': '2026-01-01T00:00:00Z',
          'expirationDate': '2026-02-01T00:00:00Z',
          'quantity': 20,
          'remainingQuantity': 18,
          'status': 'low stock',
          'received': true,
          'receivedAt': '2026-01-02T00:00:00Z',
        });

        expect(batch.requestedQuantity, 12);
        expect(batch.exportedQuantity, 2);
        expect(batch.status, InventoryBatchStatus.LOW_STOCK);
        expect(batch.receivedAt, isNotNull);

        final simple = InventoryBatchSimpleResponse.fromJson({
          'batchId': 1,
          'product': {'productName': 'Tea'},
          'remainingQuantity': 3,
          'status': 'GOOD',
        });
        expect(simple.productName, 'Tea');

        final barcode = InventoryBatchBarcodeResponse.fromJson({
          'batchId': '5',
          'barcode': 'BC',
          'productId': '6',
          'importDate': '2026-01-01',
          'expirationDate': '2026-01-31',
          'quantity': '9',
          'remainingQuantity': '8',
          'status': 'NORMAL',
        });
        expect(barcode.productId, 6);
      },
    );

    test('parses inventory export and transaction responses', () {
      final export = InventoryExportResponse.fromJson({
        'product': {'productId': 1, 'productName': 'Milk', 'productCode': 'P1'},
        'requestedQuantity': '10',
        'exportedQuantity': 8,
        'remainingStock': 2,
        'batches': [
          {'batchId': '1', 'exportedQuantity': '3', 'remainingQuantity': '7'},
          'ignored',
        ],
      });
      expect(export.batches.single.exportedQuantity, 3);

      final transaction = InventoryTransactionResponse.fromJson({
        'transactionId': 4,
        'batch': {'batchId': 1, 'remainingQuantity': 7, 'status': 'GOOD'},
        'type': 'EXPORT',
        'quantity': 3,
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(transaction.batch!.status, InventoryBatchStatus.GOOD);
    });

    test('parses nested order route warehouse and vehicle data', () {
      final order = OrderModel.fromJson({
        'orderId': 9,
        'orderCode': 'O-9',
        'customerName': 'Lan',
        'phone': '090',
        'deliveryAddress': 'District 1',
        'deliveryProvince': 'HCM',
        'latitude': 10.1,
        'longitude': 106.2,
        'assignedHub': _warehouseJson(id: 1),
        'routeConfig': _routeJson(),
        'totalAmount': 120.5,
        'paymentType': 'COD',
        'status': 'NEW',
        'totalWeightKg': 2,
        'totalVolumeM3': 0.5,
        'createdAt': '2026-01-01',
        'items': [
          {
            'itemId': 1,
            'productName': 'Milk',
            'quantityOrdered': 2,
            'unitPrice': 10,
          },
        ],
      });

      expect(order.assignedHub!.type, WarehouseType.HUB);
      expect(order.routeConfig!.dispatchType, DispatchType.CAPACITY);
      expect(order.items.single.quantityOrdered, 2);
    });

    test('parses common master data models with defaults', () {
      expect(
        CustomerAddressModel.fromJson({'latitude': 1, 'longitude': 2}).label,
        isNotEmpty,
      );
      expect(
        CustomerAddressRequest(
          receiverName: 'A',
          phone: '1',
          provinceCode: 79,
          provinceName: 'HCM',
          deliveryAddress: 'Addr',
          latitude: 1,
          longitude: 2,
          isDefault: true,
          label: 'Home',
        ).toJson(),
        containsPair('isDefault', true),
      );
      expect(DriverModel.fromJson({'driverId': '7', 'phone': 123}).driverId, 7);
      expect(
        UserModel.fromJson({
          'userId': '8',
          'roleId': 1,
          'fullName': 'A',
        }).userId,
        8,
      );
      expect(ExceptionReasonModel.fromJson({}).isActive, isTrue);
      expect(
        ExceptionReasonCreateRequest(
          category: 'ORDER',
          reasonText: 'Broken',
        ).toJson(),
        containsPair('isActive', true),
      );
      expect(
        ProductCategoryResponse.fromJson({'categoryId': 1}).categoryCode,
        '',
      );
      expect(
        ProductCategoryCreateRequest(
          categoryCode: 'C',
          categoryName: 'Cat',
        ).toJson(),
        containsPair('categoryName', 'Cat'),
      );
      expect(
        SupplierResponse.fromJson({'createdAt': '2026-01-01'}).createdAt,
        isNotNull,
      );
      expect(
        SupplierCreateRequest(supplierName: 'S').toJson(),
        containsPair('supplierName', 'S'),
      );
      expect(
        UnitResponse.fromJson({'id': '2', 'code': 'KG', 'type': 'weight'}).type,
        UnitType.WEIGHT,
      );
      expect(
        ZoneModel.fromJson({
          'coverageArea': {'a': 1},
          'createAt': 'bad',
        }).createAt,
        isNull,
      );
      expect(
        OrderTrackingModel.fromJson({
          'trackingId': 3,
          'latitude': 1,
        }).trackingId,
        3,
      );
    });

    test('parses trip, pallet, and notification models', () {
      final notification = NotificationModel.fromJson({
        'id': '10',
        'title': 'Route changed',
        'message': 'Check new route',
        'type': 'ROUTE',
        'recipientId': 2.0,
        'referenceType': 'ORDER',
        'referenceId': '9',
        'read': 'true',
        'readAt': '2026-01-02T00:00:00Z',
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(notification.isRead, isTrue);
      expect(notification.copyWith(isRead: false).isRead, isFalse);

      final linehaulDriver = LinehaulTripDriverModel.fromJson({
        'id': '1',
        'driver': {'driverId': '7', 'name': 'Driver'},
        'role': 'MAIN',
        'assignedAt': '2026-01-01',
      });
      expect(linehaulDriver.driver!.driverId, 7);
      expect(role.MAIN.displayName, isNotEmpty);

      final palletItem = PalletItemModel.fromJson({
        'id': '2',
        'order': _orderJson(),
        'scannedAt': '2026-01-01T00:00:00Z',
      });
      expect(palletItem.isScanned, isTrue);

      final pallet = PalletModel.fromJson({
        'palletId': '3',
        'palletCode': 'PLT-3',
        'barcodeUrl': 'barcode.png',
        'palletItems': [
          {'id': 4, 'isScanned': 'false'},
        ],
        'status': 'CREATING',
        'totalWeightKg': '20.5',
        'totalVolumeM3': 1,
        'isCreatedSystem': true,
      });
      expect(pallet.palletItems!.single.isScanned, isFalse);
      expect(pallet.totalWeightKg, 20.5);
      expect(PalletStatus.CAN_SEAL.displayName, isNotEmpty);

      final localDetail = LocalTripDetailModel.fromJson({
        'id': 5.0,
        'order': _orderJson(),
        'stopOrder': '2',
        'barcodeScanned': true,
        'status': 'ARRIVED',
        'localTripDetailCode': 'LTD-1',
      });
      expect(localDetail.status, LocalTripDetailStatus.ARRIVED);

      final localTrip = LocalTripModel.fromJson({
        'localTripId': '6',
        'hub': _warehouseJson(),
        'driver': {'driverId': 7},
        'vehicle': _vehicleJson(),
        'status': 'EXECUTING',
        'createdAt': '2026-01-01T00:00:00Z',
        'details': [
          {'id': 8, 'status': 'PENDING'},
        ],
        'localTripCode': 'LT-6',
        'vrpEstimatedMinutes': '45',
      });
      expect(localTrip.details, hasLength(1));
      expect(localTrip.status, LocalTripStatus.EXECUTING);

      final linehaul = LinehaulTripModel.fromJson({
        'linehaulId': '9',
        'routeConfig': _routeJson(),
        'linehaulTripDriver': [
          {'id': 1, 'role': 'ASSISTANT'},
        ],
        'pallets': [
          {'palletId': 3},
        ],
        'vehicle': _vehicleJson(),
        'status': 'ARRIVED',
        'departureTime': '2026-01-01T00:00:00Z',
        'arrivalTime': '2026-01-02T00:00:00Z',
        'linehaulTripCode': 'LH-9',
      });
      expect(linehaul.pallets!.single.palletId, 3);
      expect(linehaul.status, LinehaulTripStatus.ARRIVED);
      expect(LocalTripStatus.COMPLETED.displayName, isNotEmpty);
      expect(LocalTripDetailStatus.FAILED.displayName, isNotEmpty);
      expect(LinehaulTripStatus.CAN_START.displayName, isNotEmpty);
    });
  });

  group('enum helpers', () {
    test(
      'exposes labels, api values, fallback values, and invalid status errors',
      () {
        expect(WarehouseType.CDC.displayName, isNotEmpty);
        expect(VehicleType.BIG_TRUCK.displayName, isNotEmpty);
        expect(VehicleStatus.MAINTENANCE.displayName, isNotEmpty);
        expect(DispatchType.TIME.displayName, isNotEmpty);
        expect(InventoryBatchStatus.GOOD.label, isNotEmpty);
        expect(InventoryBatchStatus.LOW_STOCK.apiValue, 'LOW_STOCK');
        expect(InventoryBatchStatusX.isValidApiValue('GOOD'), isTrue);
        expect(
          InventoryBatchStatusX.fromApiValue('out of stock'),
          InventoryBatchStatus.OUT_OF_STOCK,
        );
        expect(
          () => InventoryBatchStatusX.fromApiValue('unknown'),
          throwsArgumentError,
        );

        expect(
          WarehouseModel.fromJson({'type': 'MISSING'}).type,
          WarehouseType.CDC,
        );
        expect(
          VehicleModel.fromJson({
            'vehicleType': 'NOPE',
            'status': 'NOPE',
          }).status,
          VehicleStatus.INACTIVE,
        );
        expect(
          RouteConfigModel.fromJson({
            'fromWarehouse': <String, dynamic>{},
            'toWarehouse': <String, dynamic>{},
          }).dispatchType,
          DispatchType.TIME,
        );
      },
    );
  });
}

Map<String, dynamic> _warehouseJson({int id = 1}) => {
  'warehouseId': id,
  'name': 'Hub $id',
  'type': 'HUB',
  'address': 'Address',
  'province': 'HN',
  'latitude': 21.0,
  'longitude': 105.0,
};

Map<String, dynamic> _vehicleJson() => {
  'vehicleId': 1,
  'licensePlate': '51A-001',
  'vehicleType': 'SMALL_TRUCK',
  'maxWeightKg': 1000,
  'maxVolumeM3': 8,
  'status': 'ACTIVE',
};

Map<String, dynamic> _routeJson() => {
  'routeId': 1,
  'routeName': 'HN-HCM',
  'fromWarehouse': _warehouseJson(id: 1),
  'toWarehouse': _warehouseJson(id: 2),
  'dispatchType': 'CAPACITY',
  'defaultVehicle': _vehicleJson(),
  'cutoffTime': '08:00',
  'provinceNames': ['HN', 'HCM'],
  'isActive': true,
};

Map<String, dynamic> _orderJson() => {
  'orderId': 1,
  'orderCode': 'O-1',
  'customerName': 'Customer',
  'phone': '090',
  'deliveryAddress': 'Address',
  'deliveryProvince': 'HN',
  'latitude': 21,
  'longitude': 105,
  'totalAmount': 100,
  'paymentType': 'COD',
  'status': 'NEW',
  'totalWeightKg': 1,
  'totalVolumeM3': 0.1,
  'createdAt': '2026-01-01',
  'items': const <Map<String, dynamic>>[],
};
