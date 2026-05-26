import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/dashboard_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/export_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/import_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/invoice/screens/financial_dashboard_screen.dart';
import 'package:smartlogisticssystem/feature/invoice/screens/invoice_list_screen.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/suppliers_page.dart';
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
          path: '/import',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ImportPage()),
        ),
        GoRoute(
          path: '/export',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExportPage()),
        ),

        GoRoute(
          path: '/suppliers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SuppliersPage()),
        ),
        GoRoute(
          path: '/invoices',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: InvoiceListScreen()),
        ),
        GoRoute(
          path: '/financial-dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FinancialDashboardScreen()),
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
    '/import' => 'Nhập hàng',
    '/export' => 'Xuất hàng',
    '/reports' => 'Báo cáo',
    '/suppliers' => 'Nhà cung cấp',
    '/invoices' => 'Quản lý Hóa đơn',
    '/financial-dashboard' => 'Dashboard Tài chính',
    '/settings' => 'Cài đặt',
    _ => 'Smart Logistics',
  };
}
