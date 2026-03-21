import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/network/dio_client.dart';

final gymStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final res = await apiCall(dio.get('/gym/status'));
    return res['data']?['is_open'] ?? true;
  } catch (_) { return true; }
});

final todayAttendanceProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final res = await apiCall(dio.get('/attendance/today'));
    if (res['success'] == true) return res['data'];
  } catch (_) {}
  return null;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final gymStatus = ref.watch(gymStatusProvider);
    final todayAtt = ref.watch(todayAttendanceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Power House', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Member Dashboard', style: const TextStyle(color: AppColors.text2, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.lime, Color(0xFF8BC800)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.limeGlow, blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: Text((user?.name ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.bg)),
              ),
            ),
          ),
        ],
      ),
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
            backgroundColor: const Color(0xFF10101C),
            onRefresh: () async {
              ref.invalidate(gymStatusProvider);
              ref.invalidate(todayAttendanceProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Greeting
                  Text(_greeting(user?.name), style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  gymStatus.when(
                    data: (open) => Row(children: [
                      PulseDot(color: open ? AppColors.lime : AppColors.coral),
                      const SizedBox(width: 8),
                      Text(open ? 'Gym is OPEN today' : 'Gym is CLOSED today',
                        style: TextStyle(color: open ? AppColors.lime : AppColors.coral, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    loading: () => const SizedBox(height: 18),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Hero QR button
                  GestureDetector(
                    onTap: () => context.go('/scan'),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.lime.withOpacity(0.15), AppColors.lime.withOpacity(0.04)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.lime.withOpacity(0.25)),
                      ),
                      child: Stack(
                        children: [
                          // Glow orb
                          Positioned(top: -20, right: -20, child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lime.withOpacity(0.08)),
                          )),
                          Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 68, height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.lime, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.lime.withOpacity(0.5), blurRadius: 28, spreadRadius: 4)],
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.bg, size: 34),
                              ),
                              const SizedBox(height: 16),
                              Text('TAP TO SCAN QR', style: GoogleFonts.spaceGrotesk(color: AppColors.lime, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              const Text('Mark your attendance', style: TextStyle(color: AppColors.text2, fontSize: 12)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Today's attendance
                  todayAtt.when(
                    data: (att) => GlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("TODAY'S RECORD", style: TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 16),
                        Row(children: [
                          _AttTile('Check In', att?['time_in'], AppColors.lime),
                          const SizedBox(width: 12),
                          _AttTile('Check Out', att?['time_out'], AppColors.blue),
                        ]),
                      ]),
                    ),
                    loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.lime, strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Membership card
                  GlassCard(
                    borderColor: AppColors.lime.withOpacity(0.2),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.lime, size: 18),
                        const SizedBox(width: 8),
                        Text('MEMBERSHIP', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lime, letterSpacing: 1)),
                      ]),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _MemberDetail('Plan', user?.membershipPlan ?? 'Standard'),
                            _vDivider(),
                            _MemberDetail('Expires', user?.membershipExpiry != null ? _shortDate(user!.membershipExpiry!) : 'N/A'),
                            _vDivider(),
                            _MemberDetail('Status', user?.status?.toUpperCase() ?? 'ACTIVE'),
                          ],
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Nav strip
                  Row(children: [
                    _NavChip(Icons.history_rounded, 'History', () => context.go('/history')),
                    const SizedBox(width: 12),
                    _NavChip(Icons.person_outline_rounded, 'Profile', () => context.go('/profile')),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(String? name) {
    final h = DateTime.now().hour;
    final time = h < 12 ? 'Morning' : h < 17 ? 'Afternoon' : 'Evening';
    return 'Good $time${name != null ? ', ${name.split(' ').first}' : ''}';
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch { return iso; }
  }
}

class _AttTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _AttTile(this.label, this.value, this.color);

  String _fmt(dynamic v) {
    if (v == null) return '--:--';
    try { final d = DateTime.parse(v.toString()).toLocal(); return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; }
    catch { return '--:--'; }
  }

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : AppColors.glass2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? color.withOpacity(0.25) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(_fmt(value), style: GoogleFonts.spaceGrotesk(color: active ? color : AppColors.text3, fontWeight: FontWeight.w700, fontSize: 20)),
      ]),
    ));
  }
}

Widget _vDivider() => Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), color: AppColors.border);

class _MemberDetail extends StatelessWidget {
  final String l, v;
  const _MemberDetail(this.l, this.v);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Text(l, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
    const SizedBox(height: 4),
    Text(v, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)),
  ]));
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavChip(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.lime, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        const Icon(Icons.chevron_right, color: AppColors.text3, size: 18),
      ]),
    ),
    ),
  ));
}
