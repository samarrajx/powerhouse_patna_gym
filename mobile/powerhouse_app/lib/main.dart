import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/user_dashboard.dart';
import 'features/dashboard/admin_dashboard.dart';

void main() {
  runApp(const ProviderScope(child: PowerHouseApp()));
}

class PowerHouseApp extends ConsumerWidget {
  const PowerHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Power House Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }
    
    // Role-based redirection
    if (authState.role == 'admin') {
      return const AdminDashboard();
    } else {
      return const UserDashboard();
    }
  }
}
