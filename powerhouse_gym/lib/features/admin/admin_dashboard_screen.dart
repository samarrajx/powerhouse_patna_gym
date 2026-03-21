import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/network/dio_client.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await apiCall(dio.get('/admin/dashboard'));
    return res['data'] ?? {};
  } catch (_) { return {}; }
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(adminStatsProvider);
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Morning' : h < 17 ? 'Afternoon' : 'Evening';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18)),
            const Text('Power House Gym', style: TextStyle(color: AppColors.text2, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 18),
            label: const Text('Logout', style: TextStyle(color: AppColors.coral, fontSize: 13)),
          ),
        ],
      ),
      drawer: _AdminDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF0E120A), AppColors.bg, Color(0xFF080C14)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.lime,
            onRefresh: () async => ref.invalidate(adminStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text('Good $greeting, ${user?.name?.split(' ').first ?? 'Admin'}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const PulseDot(),
                    const SizedBox(width: 8),
                    const Text('System operational', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                  ]),
                  const SizedBox(height: 24),

                  // Stat cards
                  stats.when(
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2),
                    )),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (d) => Column(children: [
                      Row(children: [
                        Expanded(child: StatCard(label: "Active Members", value: '${d['total_users'] ?? 0}', icon: Icons.people_outline_rounded, accent: AppColors.text1)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(label: "Today's Check-ins", value: '${d['today_attendance'] ?? 0}', icon: Icons.qr_code_scanner_rounded, accent: AppColors.lime, sub: 'Live count')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: StatCard(label: 'Inactive Members', value: '${d['inactive_users'] ?? 0}', icon: Icons.person_off_outlined, accent: AppColors.coral)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(label: 'Expiring Soon', value: '${d['expiring_soon'] ?? 0}', icon: Icons.timer_outlined, accent: AppColors.blue)),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Text('QUICK ACTIONS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  ...[
                    _ActionTile(Icons.qr_code_rounded, 'Generate QR Code', 'Create 60s attendance token', AppColors.lime, () => context.go('/admin/qr')),
                    _ActionTile(Icons.people_alt_outlined, 'Manage Members', 'Add, edit, deactivate memberships', AppColors.blue, () => context.go('/admin/users')),
                    _ActionTile(Icons.how_to_reg_outlined, "Today's Attendance", "Monitor live check-in log", AppColors.coral, () => context.go('/admin/attendance')),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.title, this.sub, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppColors.text2, fontSize: 12)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.6), size: 16),
      ]),
    ),
  );
}

class _AdminDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF0C0C18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.lime.withOpacity(0.12), Colors.transparent]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bolt_rounded, color: AppColors.bg, size: 26)),
              const SizedBox(height: 12),
              Text('POWER HOUSE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.lime)),
              const Text('Admin Console', style: TextStyle(color: AppColors.text2, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          ...[
            (Icons.dashboard_outlined, 'Dashboard', '/admin'),
            (Icons.qr_code_rounded, 'QR Station', '/admin/qr'),
            (Icons.people_alt_outlined, 'Members', '/admin/users'),
            (Icons.checklist_rounded, 'Attendance', '/admin/attendance'),
          ].map(((IconData, String, String) item) => ListTile(
            leading: Icon(item.$1, color: AppColors.text2, size: 20),
            title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(context); context.go(item.$3); },
          )),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 20),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w500)),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
