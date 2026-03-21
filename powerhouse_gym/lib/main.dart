import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PowerHouseApp()));
}

class PowerHouseApp extends ConsumerWidget {
  const PowerHouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return AnimatedTheme(
      // AnimatedTheme requires a ThemeData, not ThemeMode, so we pass it directly
      data: themeMode == ThemeMode.dark ? AppTheme.dark() : AppTheme.light(),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: MaterialApp.router(
        title: 'Power House Gym',
        debugShowCheckedModeBanner: false,
        theme:      AppTheme.light(),
        darkTheme:  AppTheme.dark(),
        themeMode:  themeMode,
        routerConfig: router,
      ),
    );
  }
}
