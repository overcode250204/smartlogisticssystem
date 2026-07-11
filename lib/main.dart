import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartlogisticssystem/core/app_router.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      if (dotenv.env['FIREBASE_PROJECT_ID'] != null && dotenv.env['FIREBASE_APP_ID'] != null) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
            appId: dotenv.env['FIREBASE_APP_ID']!,
            messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
            projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }
  
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
