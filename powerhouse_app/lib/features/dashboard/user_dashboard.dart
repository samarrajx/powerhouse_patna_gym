import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "POWER HOUSE",
                style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const GymStatusWidget(),
              const SizedBox(height: 32),
              const AttendanceStatusCard(),
              const Spacer(),
              Center(
                child: ScanQrButton(
                  onTap: () => Navigator.pushNamed(context, '/scan'),
                ),
              ),
              const Spacer(),
              const BottomNav()
            ],
          )
        )
      )
    );
  }
}

class GymStatusWidget extends StatelessWidget {
  const GymStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFCAFD00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCAFD00).withOpacity(0.5))
      ),
      child: const Text(
        "🟢 GYM OPEN TODAY",
        style: TextStyle(color: Color(0xFFCAFD00), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Attendance", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          const Text("Checked In at 07:15 AM", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      )
    );
  }
}

class ScanQrButton extends StatelessWidget {
  final VoidCallback onTap;
  const ScanQrButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF3FFCA), Color(0xFFCAFD00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
             BoxShadow(color: const Color(0xFFCAFD00).withOpacity(0.2), blurRadius: 30, spreadRadius: 10)
          ]
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFF3A4A00)),
              SizedBox(height: 8),
              Text("SCAN", style: TextStyle(color: Color(0xFF3A4A00), fontWeight: FontWeight.bold, fontSize: 16))
            ],
          )
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(icon: const Icon(Icons.home, color: Color(0xFFCAFD00)), onPressed: (){}),
        IconButton(icon: const Icon(Icons.history, color: Colors.grey), onPressed: (){}),
        IconButton(icon: const Icon(Icons.person, color: Colors.grey), onPressed: (){}),
      ],
    );
  }
}
