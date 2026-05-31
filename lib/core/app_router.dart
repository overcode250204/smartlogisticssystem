import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/dashboard_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/export_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/import_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/suppliers_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/barcode_scan_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/staff_batch_detail_page.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
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
    '/settings' => 'Cài đặt',
    _ => 'Smart Logistics',
  };
}
