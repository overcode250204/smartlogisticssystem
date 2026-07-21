import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/widgets/inventory_stat_card.dart';
import 'package:smartlogisticssystem/widgets/status_chip.dart';

void main() {
  group('StatusChip', () {
    testWidgets('renders inventory status with mapped colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusChip.inventory('expired'),
                StatusChip.inventory('low stock'),
                StatusChip.inventory('available'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('expired'), findsOneWidget);
      expect(find.text('low stock'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);
    });

    testWidgets('normalizes transaction labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusChip.transaction('export'),
                StatusChip.transaction('import'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('EXPORT'), findsOneWidget);
      expect(find.text('IMPORT'), findsOneWidget);
    });
  });

  testWidgets('InventoryStatCard renders its dashboard values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryStatCard(
            title: 'Inventory',
            value: '120',
            subtitle: '+12 today',
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('+12 today'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2), findsOneWidget);
  });

  group('apiErrorMessage', () {
    test('returns friendly messages for network and http errors', () {
      final requestOptions = RequestOptions(path: '/orders');

      expect(
        apiErrorMessage(DioException(requestOptions: requestOptions)),
        isNotEmpty,
      );
      expect(
        apiErrorMessage(
          DioException(
            requestOptions: requestOptions,
            response: Response(requestOptions: requestOptions, statusCode: 403),
          ),
        ),
        isNotEmpty,
      );
      expect(
        apiErrorMessage(
          DioException(
            requestOptions: requestOptions,
            response: Response(requestOptions: requestOptions, statusCode: 500),
          ),
        ),
        isNotEmpty,
      );
    });

    test('prefers validation, message, error, and exception fallbacks', () {
      final requestOptions = RequestOptions(path: '/orders');

      expect(
        apiErrorMessage(
          DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 400,
              data: {
                'errors': {'field': 'Required'},
              },
            ),
          ),
        ),
        'Required',
      );
      expect(
        apiErrorMessage(
          DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              data: {'message': 'DioException failed'},
            ),
          ),
        ),
        isNotEmpty,
      );
      expect(
        apiErrorMessage(
          DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              data: {'error': 'bad request'},
            ),
          ),
        ),
        'bad request',
      );
      expect(apiErrorMessage(Exception('plain')), 'plain');
    });
  });
}
