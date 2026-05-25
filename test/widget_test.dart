import 'package:flutter_test/flutter_test.dart';
import 'package:smartlogisticssystem/main.dart';

void main() {
  testWidgets('Smart Logistics dashboard smoke test', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Smart Logistics'), findsOneWidget);
    expect(find.text('Quản lý kho'), findsWidgets);
  });
}
