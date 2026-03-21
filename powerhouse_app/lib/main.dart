import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/dashboard/user_dashboard.dart';
import 'features/attendance/qr_scanner_screen.dart';

void main() {
  runApp(const ProviderScope(child: PowerHouseGymApp()));
}

class PowerHouseGymApp extends StatelessWidget {
  const PowerHouseGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power House Gym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFCAFD00), // Electric Lime
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCAFD00),
          secondary: Color(0xFFECE856),
          surface: Color(0xFF1A1A1A),
          error: Color(0xFFFF7351),
        ),
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const UserDashboardScreen(),
        '/scan': (context) => const QrScannerScreen(),
      },
    );
  }
}
