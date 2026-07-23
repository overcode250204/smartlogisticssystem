import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/login_screen.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/mobile_login_screen.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/role_select_screen.dart';
import 'package:smartlogisticssystem/feature/authentication/screens/splash_screen.dart';
import 'package:smartlogisticssystem/feature/driver/driver_screens/driver_screen.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/staff_screen.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/pallet_task_detail_page.dart';
import 'package:smartlogisticssystem/feature/staff/staff_screens/pallet_task_list_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/dashboard_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/export_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/import_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/inventory_management_screen.dart';
import 'package:smartlogisticssystem/feature/supplier/screens/suppliers_page.dart';
import 'package:smartlogisticssystem/feature/product/screens/create_product_page.dart';
import 'package:smartlogisticssystem/feature/product/screens/edit_product_page.dart';
import 'package:smartlogisticssystem/feature/product/product_detail/product_detail_page.dart';
import 'package:smartlogisticssystem/feature/product/product_management/product_management_page.dart';
import 'package:smartlogisticssystem/feature/category/screens/categories_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/barcode_scan_page.dart';
import 'package:smartlogisticssystem/feature/inventory/screens/staff_batch_detail_page.dart';
import 'package:smartlogisticssystem/data/model/inventory_batch_response_model.dart';
import 'package:smartlogisticssystem/feature/user/screens/user_screens.dart';
import 'package:smartlogisticssystem/feature/zone/screens/zone_management_page.dart';
import 'package:smartlogisticssystem/feature/vehicle/screens/vehicle_management_page.dart';
import 'package:smartlogisticssystem/feature/warehouse/screens/warehouse_management_page.dart';
import 'package:smartlogisticssystem/feature/route_config/screens/route_config_management_page.dart';
import 'package:smartlogisticssystem/feature/order/screens/order_management_page.dart';
import 'package:smartlogisticssystem/feature/dispatch_trip/screens/dispatch_management_page.dart';
import 'package:smartlogisticssystem/feature/trip_dashboard/screens/trip_dashboard_page.dart';
import 'package:smartlogisticssystem/widgets/app_shell.dart';
import 'package:smartlogisticssystem/feature/exception_reason/screens/exception_reasons_page.dart';
// Customer portal
import 'package:smartlogisticssystem/feature/customer/screens/customer_shell.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_dashboard.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_products_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_product_detail_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_cart_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_checkout_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_orders_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_order_detail_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_tracking_screen.dart';
import 'package:smartlogisticssystem/feature/customer/screens/customer_profile_screen.dart';
import 'package:smartlogisticssystem/feature/live_tracking/screens/live_tracking_map_page.dart';
import 'package:smartlogisticssystem/feature/admin_ai/screens/admin_ai_assistant_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: '/mobile-login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: MobileLoginScreen()),
    ),
    GoRoute(
      path: '/role-select',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: RoleSelectScreen()),
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
    GoRoute(
      path: '/staff/pallet-tasks',
      redirect: (context, state) async {
        if (!await AuthSession.isStaff()) return '/login';
        return null;
      },
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: PalletTaskListPage()),
    ),
    GoRoute(
      path: '/staff/pallet-tasks/:id',
      redirect: (context, state) async {
        if (!await AuthSession.isStaff()) return '/login';
        return null;
      },
      pageBuilder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const NoTransitionPage(child: PalletTaskListPage());
        }
        return NoTransitionPage(child: PalletTaskDetailPage(palletId: id));
      },
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
            return const NoTransitionPage(
              child: UserListScreen(currentRoleId: 1),
            );
          },
        ),
        GoRoute(
          path: '/zones',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard'; // Redirect non-admins to dashboard
            }
            return null; // Allow access
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: ZoneManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/vehicles',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard';
            }
            return null;
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: VehicleManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/warehouses',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard';
            }
            return null;
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: WarehouseManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/route-configs',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard';
            }
            return null;
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: RouteConfigManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/orders',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard'; // Redirect non-admins to dashboard
            }
            return null; // Allow access
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: OrderManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/dispatch',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard'; // Redirect non-admins to dashboard
            }
            return null; // Allow access
          },
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: DispatchManagementPage(),
            );
          },
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/trip-dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TripDashboardPage()),
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
          path: '/products',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProductManagementPage()),
          routes: [
            GoRoute(
              path: 'create',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CreateProductPage()),
            ),
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return NoTransitionPage(
                  child: ProductDetailPage(productId: id),
                );
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  pageBuilder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return NoTransitionPage(
                      child: EditProductPage(productId: id),
                    );
                  },
                ),
              ],
            ),
          ],
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
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CategoriesPage()),
        ),
        GoRoute(
          path: '/exception-reasons',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard'; // Redirect non-admins to dashboard
            }
            return null; // Allow access
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExceptionReasonsPage()),
        ),
        GoRoute(
          path: '/live-tracking',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard';
            }
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LiveTrackingMapPage()),
        ),
        GoRoute(
          path: '/admin-ai-assistant',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 1) {
              return '/dashboard';
            }
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminAiAssistantPage()),
        ),
      ],
    ),

    // ── Customer Portal (roleId == 5) ──────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return CustomerShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/customer',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerDashboard()),
        ),
        GoRoute(
          path: '/customer/products',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerProductsScreen()),
        ),
        GoRoute(
          path: '/customer/products/:id',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerProductDetailScreen(productId: id));
          },
        ),
        GoRoute(
          path: '/customer/cart',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerCartScreen()),
        ),
        GoRoute(
          path: '/customer/checkout',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerCheckoutScreen()),
        ),
        GoRoute(
          path: '/customer/orders',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerOrdersScreen()),
        ),
        GoRoute(
          path: '/customer/orders/:id',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerOrderDetailScreen(orderId: id));
          },
        ),
        GoRoute(
          path: '/customer/orders/:id/tracking',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerTrackingScreen(orderId: id));
          },
        ),
        GoRoute(
          path: '/customer/profile',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerProfileScreen()),
        ),
      ],
    ),

    // ── Customer Portal (roleId == 5) ──────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return CustomerShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/customer',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            final roleId = prefs.getInt('roleId');
            if (roleId != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerDashboard()),
        ),
        GoRoute(
          path: '/customer/products',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerProductsScreen()),
        ),
        GoRoute(
          path: '/customer/products/:id',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerProductDetailScreen(productId: id));
          },
        ),
        GoRoute(
          path: '/customer/cart',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerCartScreen()),
        ),
        GoRoute(
          path: '/customer/checkout',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerCheckoutScreen()),
        ),
        GoRoute(
          path: '/customer/orders',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerOrdersScreen()),
        ),
        GoRoute(
          path: '/customer/orders/:id',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerOrderDetailScreen(orderId: id));
          },
        ),
        GoRoute(
          path: '/customer/orders/:id/tracking',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return NoTransitionPage(child: CustomerTrackingScreen(orderId: id));
          },
        ),
        GoRoute(
          path: '/customer/profile',
          redirect: (context, state) async {
            final prefs = await SharedPreferences.getInstance();
            if ((prefs.getInt('roleId') ?? 0) != 5) return '/login';
            return null;
          },
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CustomerProfileScreen()),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
);

String _titleForPath(String path) {
  if (RegExp(r'^/products/\d+/edit$').hasMatch(path)) {
    return 'Chỉnh sửa sản phẩm';
  }

  if (RegExp(r'^/products/\d+$').hasMatch(path)) {
    return 'Chi tiết sản phẩm';
  }

  return switch (path) {
    '/dashboard' => 'Tổng quan',
    '/trip-dashboard' => 'Trip Dashboard',
    '/inventory' => 'Quản lý kho',
    '/barcode-gen' => 'Tạo mã vạch',
    '/barcode-scan' => 'Quét mã vạch',
    '/export' => 'Xuất hàng',
    '/reports' => 'Báo cáo',
    '/suppliers' => 'Nhà cung cấp',
    '/categories' => 'Danh mục',
    '/exception-reasons' => 'Lý do ngoại lệ',
    '/live-tracking' => 'Giám sát live',
    '/admin-ai-assistant' => 'Trợ lý vận hành AI',
    '/users' => 'Quản lý nhân sự',
    '/zones' => 'Quản lý khu vực',
    '/vehicles' => 'Quản lý phương tiện',
    '/warehouses' => 'Quản lý nhà kho',
    '/route-configs' => 'Cấu hình tuyến đường',
    '/orders' => 'Quản lý đơn hàng',
    '/settings' => 'Cài đặt',
    '/products' => 'Quản lý sản phẩm',
    '/products/create' => 'Tạo sản phẩm',
    _ => 'Smart Logistics',
  };
}
