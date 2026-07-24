import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_service.dart';
import 'package:smartlogisticssystem/feature/staff/services/pallet_task_state.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/pallet_task_detail_page.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/pallet_task_list_page.dart';

Map<String, dynamic> orderJson(String code, {String status = 'READY_TO_PICK'}) {
  return {
    'orderId': code.hashCode.abs() % 10000,
    'orderCode': code,
    'customerName': 'Khach $code',
    'phone': '0900000000',
    'deliveryAddress': 'So 1',
    'deliveryProvince': 'Ha Noi',
    'latitude': 21.0,
    'longitude': 105.0,
    'totalAmount': 100000,
    'paymentType': 'COD',
    'status': status,
    'totalWeightKg': 1.5,
    'totalVolumeM3': 0.02,
    'createdAt': '2026-07-20T08:00:00',
    'items': <dynamic>[],
  };
}

Map<String, dynamic> palletJson({
  int palletId = 1,
  String palletCode = 'PL-000000000001',
  String status = 'CAN_SEAL',
  List<Map<String, dynamic>> items = const [],
}) {
  return {
    'palletId': palletId,
    'palletCode': palletCode,
    'status': status,
    'createdAt': '2026-07-20T08:00:00',
    'totalWeightKg': 3.0,
    'totalVolumeM3': 0.04,
    'isCreatedSystem': true,
    'palletItems': items,
  };
}

Map<String, dynamic> itemJson(
  String orderCode, {
  bool scanned = false,
  String? orderStatus,
}) {
  return {
    'id': orderCode.hashCode.abs() % 1000,
    'order': orderJson(
      orderCode,
      status: orderStatus ?? (scanned ? 'IN_PALLET' : 'READY_TO_PICK'),
    ),
    'isScanned': scanned,
    'scannedAt': scanned ? '2026-07-21T09:00:00' : null,
  };
}

DioException apiError(int statusCode, String message) {
  final options = RequestOptions(path: '/pallet');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: {'statusCode': statusCode, 'message': message},
    ),
    type: DioExceptionType.badResponse,
  );
}

class FakePalletTaskService extends PalletTaskService {
  FakePalletTaskService();

  /// Độ trễ giả lập để test được loading state.
  Duration delay = Duration.zero;

  Future<void> _wait() => Future<void>.delayed(delay);

  List<Map<String, dynamic>> tasks = [];
  Map<String, dynamic>? detail;
  Object? listError;
  Object? detailError;
  Object? scanError;
  Object? sealError;

  int listCalls = 0;
  int detailCalls = 0;
  int scanCalls = 0;
  int sealCalls = 0;
  int canSealCalls = 0;
  List<String> scannedCodes = [];

  /// Sau khi scan thành công, backend sẽ trả detail mới -> mô phỏng bằng hàm này.
  void Function()? onScanSuccess;

  @override
  Future<List<PalletModel>> getTasks() async {
    listCalls++;
    await _wait();
    if (listError != null) throw listError!;
    return tasks.map(PalletModel.fromJson).toList();
  }

  @override
  Future<PalletModel> getTaskById(int palletId) async {
    detailCalls++;
    await _wait();
    if (detailError != null) throw detailError!;
    return PalletModel.fromJson(detail ?? palletJson());
  }

  @override
  Future<PalletItemModel> scanOrder({
    required int palletId,
    required String orderCode,
  }) async {
    scanCalls++;
    scannedCodes.add(orderCode);
    if (scanError != null) throw scanError!;
    onScanSuccess?.call();
    return PalletItemModel.fromJson(itemJson(orderCode, scanned: true));
  }

  @override
  Future<PalletModel> markCanSeal(int palletId) async {
    canSealCalls++;
    return PalletModel.fromJson(detail ?? palletJson());
  }

  @override
  Future<PalletModel> seal(int palletId) async {
    sealCalls++;
    if (sealError != null) throw sealError!;
    detail = palletJson(
      status: 'SEALED',
      items: (detail?['palletItems'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
    return PalletModel.fromJson(detail!);
  }

  Object? palletArrivalError;
  Object? orderArrivalError;
  int palletArrivalCalls = 0;
  int orderArrivalCalls = 0;
  List<String> confirmedOrders = [];
  ({double latitude, double longitude})? lastCoordinate;
  void Function()? onOrderArrivalSuccess;

  @override
  Future<PalletModel> confirmPalletArrival({
    required String palletCode,
    required double latitude,
    required double longitude,
  }) async {
    palletArrivalCalls++;
    lastCoordinate = (latitude: latitude, longitude: longitude);
    if (palletArrivalError != null) throw palletArrivalError!;
    detail = palletJson(
      status: 'ARRIVED',
      items: (detail?['palletItems'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>(),
    );
    return PalletModel.fromJson(detail!);
  }

  @override
  Future<void> confirmOrderArrival({
    required String orderCode,
    required double latitude,
    required double longitude,
  }) async {
    orderArrivalCalls++;
    confirmedOrders.add(orderCode);
    lastCoordinate = (latitude: latitude, longitude: longitude);
    if (orderArrivalError != null) throw orderArrivalError!;
    onOrderArrivalSuccess?.call();
  }
}

Future<({double latitude, double longitude})> fakeLocation() async =>
    (latitude: 21.0, longitude: 105.0);

Widget wrap(Widget child) => MaterialApp(home: child);

/// Màn hình kho thường cao; đặt viewport đủ lớn để mọi section đều được build.
Future<void> useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('PalletTaskState (rule hiển thị theo trạng thái backend)', () {
    test('CREATING: chưa được quét, chỉ được mở can-seal', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(status: 'CREATING', items: [itemJson('OD1')]),
        ),
      );
      expect(state.canScan, isFalse);
      expect(state.canMarkCanSeal, isTrue);
      expect(state.canSeal, isFalse);
      expect(state.isReadOnly, isFalse);
    });

    test('CAN_SEAL chưa quét đủ: không được seal, báo số đơn còn lại', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(
            items: [itemJson('OD1', scanned: true), itemJson('OD2')],
          ),
        ),
      );
      expect(state.canScan, isTrue);
      expect(state.canSeal, isFalse);
      expect(state.remainingCount, 1);
      expect(state.sealBlockers.join(), contains('Còn 1 đơn'));
      expect(state.unscannedOrderCodes, ['OD2']);
    });

    test('CAN_SEAL + quét đủ: được seal, không còn blocker', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(
            items: [
              itemJson('OD1', scanned: true),
              itemJson('OD2', scanned: true),
            ],
          ),
        ),
      );
      expect(state.canSeal, isTrue);
      expect(state.sealBlockers, isEmpty);
      expect(state.progress, 1.0);
    });

    test('SEALED: read-only, không quét và không seal lại', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(status: 'SEALED', items: [itemJson('OD1', scanned: true)]),
        ),
      );
      expect(state.isReadOnly, isTrue);
      expect(state.canScan, isFalse);
      expect(state.canSeal, isFalse);
    });

    test('sortedItems: đơn chưa quét lên trước và lọc theo mã', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(
            items: [itemJson('OD1', scanned: true), itemJson('OD2')],
          ),
        ),
      );
      expect(
        state.sortedItems().map((i) => i.order?.orderCode).toList(),
        ['OD2', 'OD1'],
      );
      expect(state.sortedItems(query: 'od1').length, 1);
    });
  });

  group('PalletTaskListPage', () {
    testWidgets('render danh sách task với progress', (tester) async {
      final service = FakePalletTaskService()
        ..tasks = [
          palletJson(
            items: [itemJson('OD1', scanned: true), itemJson('OD2')],
          ),
        ];

      await tester.pumpWidget(wrap(PalletTaskListPage(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('PL-000000000001'), findsOneWidget);
      expect(find.text('1/2 đơn đã quét'), findsOneWidget);
      expect(find.text('Tổng 1 nhiệm vụ'), findsOneWidget);
    });

    testWidgets('loading state hiển thị trước khi có dữ liệu', (tester) async {
      final service = FakePalletTaskService()
        ..tasks = [palletJson()]
        ..delay = const Duration(milliseconds: 50);
      await tester.pumpWidget(wrap(PalletTaskListPage(service: service)));
      await tester.pump(Duration.zero);
      expect(find.byType(Card), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('empty state khi không có nhiệm vụ', (tester) async {
      await tester.pumpWidget(
        wrap(PalletTaskListPage(service: FakePalletTaskService())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có pallet cần đóng gói'), findsOneWidget);
    });

    testWidgets('error state có nút thử lại và gọi lại API', (tester) async {
      final service = FakePalletTaskService()
        ..listError = apiError(500, 'boom');

      await tester.pumpWidget(wrap(PalletTaskListPage(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('Không tải được danh sách nhiệm vụ'), findsOneWidget);
      service.listError = null;
      service.tasks = [palletJson()];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(service.listCalls, 2);
      expect(find.text('PL-000000000001'), findsOneWidget);
    });

    testWidgets('tìm kiếm lọc theo mã pallet', (tester) async {
      final service = FakePalletTaskService()
        ..tasks = [
          palletJson(palletId: 1, palletCode: 'PL-111'),
          palletJson(palletId: 2, palletCode: 'PL-222'),
        ];
      await tester.pumpWidget(wrap(PalletTaskListPage(service: service)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'PL-222');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'PL-111'), findsNothing);
      expect(find.widgetWithText(Card, 'PL-222'), findsOneWidget);
    });
  });

  group('PalletTaskDetailPage - scan flow', () {
    testWidgets('hiển thị order và progress đúng', (tester) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(
          items: [itemJson('OD1', scanned: true), itemJson('OD2')],
        );

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã quét 1/2 đơn'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'OD1'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'OD2'), findsOneWidget);
      expect(find.text('Đã quét'), findsOneWidget);
      expect(find.text('Chưa quét'), findsOneWidget);
    });

    testWidgets('không gửi request khi mã rỗng', (tester) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(items: [itemJson('OD1')]);

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận scan'));
      await tester.pumpAndSettle();

      expect(service.scanCalls, 0);
      expect(
        find.text('Vui lòng nhập hoặc quét mã đơn hàng.'),
        findsOneWidget,
      );
    });

    testWidgets('nhấn Enter thực hiện scan và cập nhật UI', (tester) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(items: [itemJson('OD1')]);
      service.onScanSuccess = () {
        service.detail = palletJson(items: [itemJson('OD1', scanned: true)]);
      };

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'OD1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(service.scanCalls, 1);
      expect(service.scannedCodes, ['OD1']);
      expect(find.text('Đã quét 1/1 đơn'), findsOneWidget);
    });

    testWidgets('scan lỗi: hiện lỗi backend và progress không tăng', (
      tester,
    ) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(items: [itemJson('OD1')])
        ..scanError = apiError(400, 'Order already scanned');

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'OD1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Order already scanned'), findsWidgets);
      expect(find.text('Đã quét 0/1 đơn'), findsOneWidget);
    });

    testWidgets('pallet SEALED thì không có ô scan và không có nút seal', (
      tester,
    ) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(
          status: 'SEALED',
          items: [itemJson('OD1', scanned: true)],
        );

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận scan'), findsNothing);
      expect(find.text('Seal pallet'), findsNothing);
      expect(find.textContaining('chỉ xem'), findsOneWidget);
    });

    testWidgets('pallet CREATING: không scan được, có nút Bắt đầu quét', (
      tester,
    ) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(status: 'CREATING', items: [itemJson('OD1')]);

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận scan'), findsNothing);
      expect(find.text('Bắt đầu quét'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu quét'));
      await tester.pumpAndSettle();
      expect(service.canSealCalls, 1);
    });
  });

  group('PalletTaskDetailPage - seal flow', () {
    Future<FakePalletTaskService> pumpDetail(
      WidgetTester tester, {
      required List<Map<String, dynamic>> items,
    }) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(items: items);
      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('chưa quét đủ: nút seal bị disable và hiện lý do', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        items: [itemJson('OD1', scanned: true), itemJson('OD2')],
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Seal pallet'),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('Còn 1 đơn chưa quét'), findsOneWidget);
    });

    testWidgets('quét đủ: nút seal enable, có dialog xác nhận', (tester) async {
      final service = await pumpDetail(
        tester,
        items: [itemJson('OD1', scanned: true)],
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Seal pallet'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Seal pallet'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận dán seal'), findsOneWidget);

      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(service.sealCalls, 0);
    });

    testWidgets('seal thành công: refetch và chuyển read-only', (tester) async {
      final service = await pumpDetail(
        tester,
        items: [itemJson('OD1', scanned: true)],
      );
      final detailCallsBefore = service.detailCalls;

      await tester.tap(find.widgetWithText(FilledButton, 'Seal pallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dán seal'));
      await tester.pumpAndSettle();

      expect(service.sealCalls, 1);
      expect(service.detailCalls, greaterThan(detailCallsBefore));
      expect(find.text('Xác nhận scan'), findsNothing);
      expect(
        find.textContaining('chỉ xem, không thể quét thêm'),
        findsOneWidget,
      );
    });

    testWidgets('seal thất bại: không hiển thị trạng thái thành công giả', (
      tester,
    ) async {
      final service = await pumpDetail(
        tester,
        items: [itemJson('OD1', scanned: true)],
      );
      service.sealError = apiError(
        400,
        'All pallet items must be scanned before sealing the pallet',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Seal pallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dán seal'));
      await tester.pumpAndSettle();

      expect(find.text('Đã dán seal pallet thành công'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Seal pallet'), findsOneWidget);
    });

    testWidgets('403 hiển thị thông báo không có quyền', (tester) async {
      final service = FakePalletTaskService()
        ..detailError = apiError(403, 'Role has no permission');

      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(PalletTaskDetailPage(palletId: 1, service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('không có quyền'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });

  group('PalletTaskState - arrival rules', () {
    test('CAN_SEAL: chưa hiện khu vực nhận hàng', () {
      final state = PalletTaskState(
        PalletModel.fromJson(palletJson(items: [itemJson('OD1')])),
      );
      expect(state.showArrivalSection, isFalse);
      expect(state.canConfirmPalletArrival, isFalse);
    });

    test('IN_TRANSIT: cho phép confirm pallet, tính progress nhận hàng', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(
            status: 'IN_TRANSIT',
            items: [
              itemJson('OD1', orderStatus: 'ARRIVED_AT_HUB'),
              itemJson('OD2', orderStatus: 'IN_TRANSIT_LINEHAUL'),
            ],
          ),
        ),
      );
      expect(state.showArrivalSection, isTrue);
      expect(state.canConfirmPalletArrival, isTrue);
      expect(state.isPalletArrived, isFalse);
      expect(state.arrivedOrderCount, 1);
      expect(state.pendingArrivalCount, 1);
      expect(state.arrivalProgress, 0.5);
      final items = state.items;
      expect(state.canConfirmOrderArrival(items[1]), isTrue);
      expect(state.canConfirmOrderArrival(items[0]), isFalse);
      expect(state.isOrderArrived(items[0]), isTrue);
    });

    test('ARRIVED: read-only', () {
      final state = PalletTaskState(
        PalletModel.fromJson(
          palletJson(
            status: 'ARRIVED',
            items: [itemJson('OD1', orderStatus: 'ARRIVED_AT_HUB')],
          ),
        ),
      );
      expect(state.isPalletArrived, isTrue);
      expect(state.isArrivalReadOnly, isTrue);
      expect(state.canConfirmPalletArrival, isFalse);
    });
  });

  group('PalletTaskDetailPage - arrival flow', () {
    Future<FakePalletTaskService> pumpArrival(
      WidgetTester tester, {
      required String status,
      required List<Map<String, dynamic>> items,
    }) async {
      final service = FakePalletTaskService()
        ..detail = palletJson(status: status, items: items);
      await useTallSurface(tester);
      await tester.pumpWidget(
        wrap(
          PalletTaskDetailPage(
            palletId: 1,
            service: service,
            locationProvider: fakeLocation,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('CAN_SEAL: không hiện section nhận hàng', (tester) async {
      await pumpArrival(
        tester,
        status: 'CAN_SEAL',
        items: [itemJson('OD1', scanned: true)],
      );
      expect(find.text('Xác nhận pallet đã đến'), findsNothing);
    });

    testWidgets('IN_TRANSIT: hiện section + progress nhận hàng', (tester) async {
      await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [
          itemJson('OD1', orderStatus: 'ARRIVED_AT_HUB'),
          itemJson('OD2', orderStatus: 'IN_TRANSIT_LINEHAUL'),
        ],
      );
      expect(find.text('Xác nhận pallet đã đến'), findsOneWidget);
      expect(find.textContaining('Đã nhận 1/2 đơn'), findsOneWidget);
    });

    testWidgets('confirm pallet: có dialog, gọi API kèm GPS, chuyển ARRIVED', (
      tester,
    ) async {
      final service = await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [itemJson('OD1', orderStatus: 'IN_TRANSIT_LINEHAUL')],
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'Xác nhận đã nhận pallet'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận đã nhận pallet?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(service.palletArrivalCalls, 1);
      expect(service.lastCoordinate?.latitude, 21.0);
      expect(find.textContaining('Pallet đã được xác nhận đến nơi'), findsOneWidget);
    });

    testWidgets('confirm pallet lỗi GPS: hiện message, không thành công giả', (
      tester,
    ) async {
      final service = await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [itemJson('OD1', orderStatus: 'IN_TRANSIT_LINEHAUL')],
      );
      service.palletArrivalError = apiError(
        400,
        'GPS location is not near the destination warehouse',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'Xác nhận đã nhận pallet'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pallet đã được xác nhận'), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'Xác nhận đã nhận pallet'),
        findsOneWidget,
      );
    });

    testWidgets('order confirm button: chỉ hiện khi IN_TRANSIT_LINEHAUL', (
      tester,
    ) async {
      await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [
          itemJson('OD1', orderStatus: 'ARRIVED_AT_HUB'),
          itemJson('OD2', orderStatus: 'IN_TRANSIT_LINEHAUL'),
        ],
      );
      // OD1 đã đến -> không có nút; OD2 -> có nút.
      expect(find.text('Xác nhận đã nhận'), findsOneWidget);
    });

    testWidgets('confirm order: gọi API và cập nhật progress', (tester) async {
      final service = await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [itemJson('OD2', orderStatus: 'IN_TRANSIT_LINEHAUL')],
      );
      service.onOrderArrivalSuccess = () {
        service.detail = palletJson(
          status: 'IN_TRANSIT',
          items: [itemJson('OD2', orderStatus: 'ARRIVED_AT_HUB')],
        );
      };

      await tester.tap(find.text('Xác nhận đã nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(service.orderArrivalCalls, 1);
      expect(service.confirmedOrders, ['OD2']);
      expect(find.textContaining('Đã nhận 1/1 đơn'), findsOneWidget);
    });

    testWidgets('scan nhận hàng: Enter gọi confirmOrderArrival, không nhầm scan', (
      tester,
    ) async {
      final service = await pumpArrival(
        tester,
        status: 'IN_TRANSIT',
        items: [itemJson('OD9', orderStatus: 'IN_TRANSIT_LINEHAUL')],
      );
      service.onOrderArrivalSuccess = () {
        service.detail = palletJson(
          status: 'IN_TRANSIT',
          items: [itemJson('OD9', orderStatus: 'ARRIVED_AT_HUB')],
        );
      };

      await tester.enterText(
        find.widgetWithText(TextField, 'Quét mã order để xác nhận đã nhận'),
        'OD9',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(service.orderArrivalCalls, 1);
      expect(service.scanCalls, 0); // không gọi nhầm API scan đóng pallet
      expect(service.confirmedOrders, ['OD9']);
    });
  });
}
