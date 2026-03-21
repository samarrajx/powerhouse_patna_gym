import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/force_change_password_screen.dart';
import '../../features/user/dashboard_screen.dart';
import '../../features/user/scanner_screen.dart';
import '../../features/user/history_screen.dart';
import '../../features/user/profile_screen.dart';
import '../../features/user/settings_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/admin/admin_qr_screen.dart';
import '../../features/admin/admin_attendance_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final loc = state.matchedLocation;

      if (!loggedIn) {
        return loc == '/login' ? null : '/login';
      }

      // If user must change password, force them there
      if (authState.mustChangePassword && loc != '/force-change-password') {
        return '/force-change-password';
      }

      // Don't send changed-password users back to force-change
      if (loc == '/force-change-password' && !authState.mustChangePassword) {
        return authState.user?.role == 'admin' ? '/admin' : '/dashboard';
      }

      // Redirect from login
      if (loc == '/login') {
        return authState.user?.role == 'admin' ? '/admin' : '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login',                builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/force-change-password',builder: (_, __) => const ForceChangePasswordScreen()),
      // User routes
      GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/scan',       builder: (_, __) => const ScannerScreen()),
      GoRoute(path: '/history',    builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
      // Admin routes
      GoRoute(path: '/admin',            builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users',      builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/qr',         builder: (_, __) => const AdminQrScreen()),
      GoRoute(path: '/admin/attendance', builder: (_, __) => const AdminAttendanceScreen()),
    ],
  );
});
