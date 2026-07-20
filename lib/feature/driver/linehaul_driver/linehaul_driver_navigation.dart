import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/feature/driver/linehaul_driver/linehaul_profile_screen.dart';
import 'package:smartlogisticssystem/feature/driver/linehaul_driver/linehaul_active_trip_screen.dart';
import 'package:smartlogisticssystem/feature/driver/linehaul_driver/linehaul_history_screen.dart';

class LinehaulDriverNavigation extends StatefulWidget {
  const LinehaulDriverNavigation({super.key});

  @override
  State<LinehaulDriverNavigation> createState() => _LinehaulDriverNavigationState();
}

class _LinehaulDriverNavigationState extends State<LinehaulDriverNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LinehaulActiveTripScreen(),
    LinehaulHistoryScreen(),
    LinehaulProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.blueAccent.shade700,
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Chuyến đi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
