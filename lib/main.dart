import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_router.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';

void main() {
  runApp(const SmartLogisticsApp());
}

class SmartLogisticsApp extends StatelessWidget {
  const SmartLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Logistics',
      debugShowCheckedModeBanner: false,
      theme: buildSmartLogisticsTheme(),
      routerConfig: appRouter,
    );
  }
}

class MyApp extends SmartLogisticsApp {
  const MyApp({super.key});
}
