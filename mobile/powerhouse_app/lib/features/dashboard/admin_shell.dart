import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../auth/auth_provider.dart';
import 'admin_dashboard.dart';
import '../admin/user_management_screen.dart';
import '../admin/qr_generator_screen.dart';
import '../admin/attendance_monitor_screen.dart';
import '../admin/more_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboard(),
    UserManagementScreen(),
    QRGeneratorScreen(),
    AttendanceMonitorScreen(),
    AdminMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(top: BorderSide(color: AppColors.surfH(context), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.sec(context),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'MEMBERS'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code), activeIcon: Icon(Icons.qr_code_scanner), label: 'QR'),
            BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'ATTEND'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_vert), label: 'MORE'),
          ],
        ),
      ),
    );
  }
}
