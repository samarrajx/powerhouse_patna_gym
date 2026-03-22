import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/user_shell.dart';
import 'features/dashboard/admin_shell.dart';

void main() {
  runApp(const ProviderScope(child: PowerHouseApp()));
}

class PowerHouseApp extends ConsumerWidget {
  const PowerHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'PH Gym',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!authState.isAuthenticated) return const LoginScreen();
    if (authState.role == 'admin') return const AdminShell();
    return const UserShell();
  }
}
