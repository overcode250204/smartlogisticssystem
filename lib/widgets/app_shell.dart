import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartlogisticssystem/core/auth_session.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/widgets/sidebar.dart';
import 'package:smartlogisticssystem/widgets/topbar.dart';

class AppShell extends StatelessWidget {
  final String location;
  final String title;
  final Widget child;

  const AppShell({
    super.key,
    required this.location,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkest,
      body: Row(
        children: [
          Sidebar(
            currentLocation: location,
            roleIdFuture: AuthSession.getRoleId(),
            onNavigate: (route) {
              if (route != location) context.go(route);
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(title: title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
