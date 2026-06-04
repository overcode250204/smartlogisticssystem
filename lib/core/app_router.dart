import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/mobile_login_screen.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/splash_screen.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_screen.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/staff_screen.dart';
=======
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
import 'package:smartlogisticssystem/feature/inventory/screens/dashboard_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/export_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/import_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/suppliers_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/barcode_scan_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/staff_batch_detail_page.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
<<<<<<< HEAD
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart';
import 'package:smartlogisticssystem/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
=======
import 'package:smartlogisticssystem/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
<<<<<<< HEAD
    GoRoute(
      path: '/mobile-login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: MobileLoginScreen()),
    ),
    GoRoute(
      path: '/driver',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: DriverScreen()),
    ),
    GoRoute(
      path: '/staff',
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final roleId = prefs.getInt('roleId');
        if (roleId != 4) {
          return '/login'; // Only staff should access /staff
        }
        return null;
      },
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: StaffScreen()),
    ),
=======
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(
          location: state.uri.path,
          title: _titleForPath(state.uri.path),
          child: child,
        );
      },
      routes: [
        GoRoute(
<<<<<<< HEAD
          path: '/users',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard'; // Redirect non-admins to dashboard
            }
            return null; // Allow access
          },
          pageBuilder: (context, state) {
            final roleId = state.extra as int?;
            return NoTransitionPage(
              child: UserListScreen(currentRoleId: roleId ?? 0),
            );
          },
        ),
        GoRoute(
=======
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
          path: '/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InventoryManagementScreen()),
        ),
        GoRoute(
          path: '/barcode-gen',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ImportPage()),
        ),
        GoRoute(
          path: '/export',
          redirect: (context, state) async {
            if (!await AuthSession.canViewExportHistory()) {
              return '/inventory';
            }
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExportPage()),
        ),
        GoRoute(
          path: '/barcode-scan',
          redirect: (context, state) async {
            if (!await AuthSession.isStaff()) return '/inventory';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StaffExportScanPage()),
          routes: [
            GoRoute(
              path: 'detail',
              redirect: (context, state) async {
                if (!await AuthSession.isStaff()) return '/inventory';
                if (state.extra is! InventoryBatchBarcodeResponse) {
                  return '/barcode-scan';
                }
                return null;
              },
              pageBuilder: (context, state) {
                final batch = state.extra as InventoryBatchBarcodeResponse;
                return MaterialPage(
                  child: StaffBarcodeExportPage(batch: batch),
                );
              },
            ),
          ],
        ),

        GoRoute(
          path: '/suppliers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SuppliersPage()),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
);

String _titleForPath(String path) {
  return switch (path) {
    '/dashboard' => 'Tổng quan',
    '/inventory' => 'Quản lý kho',
    '/barcode-gen' => 'Tạo mã vạch',
    '/barcode-scan' => 'Quét mã vạch',
    '/export' => 'Xuất hàng',
    '/reports' => 'Báo cáo',
    '/suppliers' => 'Nhà cung cấp',
<<<<<<< HEAD
    '/users' => 'Quản lý nhân sự',
=======
>>>>>>> 4725fafdc1786052c4f47eb198e47ab8eeebbcda
    '/settings' => 'Cài đặt',
    _ => 'Smart Logistics',
  };
}
