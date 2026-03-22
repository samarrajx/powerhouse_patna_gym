import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../admin/attendance_monitor_screen.dart';
import '../admin/add_user_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  Map<String, dynamic>? stats;
  List<dynamic> _todayAttendance = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    final results = await Future.wait([
      ApiService.get('/admin/dashboard'),
      ApiService.get('/admin/attendance/today'),
    ]);
    if (mounted) {
      setState(() {
        if (results[0]['success'] == true) stats = results[0]['data'];
        if (results[1]['success'] == true) _todayAttendance = results[1]['data'] ?? [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);
    final sec = AppColors.sec(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('ADMIN', style: TextStyle(color: sec, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Text('COMMAND CENTER', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 28),
                _buildStatsGrid(context),
                const SizedBox(height: 28),
                _buildSectionHeader('QUICK ACTIONS', sec),
                const SizedBox(height: 14),
                _buildActionGrid(context),
                const SizedBox(height: 28),
                _buildLiveMonitor(context, sec),
                const SizedBox(height: 28),
                if (stats?['weekly_footfall'] != null) ...[
                  _buildSectionHeader('WEEKLY FOOTFALL', sec),
                  const SizedBox(height: 14),
                  _buildFootfall(context, stats!['weekly_footfall'] as List),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, Color color) {
    return Text(text, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11, color: color));
  }

  Widget _buildStatsGrid(BuildContext context) {
    final surf = AppColors.surf(context);
    final surfH = AppColors.surfH(context);
    final onSurf = AppColors.onSurf(context);
    final sec = AppColors.sec(context);

    final tiles = [
      {'label': 'TOTAL MEMBERS', 'value': stats?['total_users']?.toString() ?? '—', 'icon': Icons.people_outline, 'color': Colors.blue},
      {'label': 'TODAY', 'value': stats?['today_attendance']?.toString() ?? '—', 'icon': Icons.how_to_reg, 'color': Colors.green},
      {'label': 'INACTIVE', 'value': stats?['inactive_users']?.toString() ?? '—', 'icon': Icons.person_off_outlined, 'color': AppColors.error},
      {'label': 'EXPIRING SOON', 'value': stats?['expiring_soon']?.toString() ?? '—', 'icon': Icons.timer_outlined, 'color': AppColors.warning},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.0 : 1.6,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final t = tiles[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surf,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: surfH),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: (t['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 18),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                isLoading
                    ? Container(width: 40, height: 20, decoration: BoxDecoration(color: surfH, borderRadius: BorderRadius.circular(4)))
                    : Text(t['value'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurf)),
                Text(t['label'] as String, style: TextStyle(fontSize: 8, color: sec, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final surfH = AppColors.surfH(context);
    final sec = AppColors.sec(context);

    final actions = [
      {'label': 'NEW MEMBER', 'icon': Icons.person_add_outlined, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())).then((_) => _fetchAll())},
      {'label': 'ATTENDANCE', 'icon': Icons.how_to_reg_outlined, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceMonitorScreen()))},
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: GestureDetector(
          onTap: a['onTap'] as VoidCallback,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: surfH, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(a['icon'] as IconData, color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(a['label'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sec, letterSpacing: 0.8)),
            ]),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildLiveMonitor(BuildContext context, Color sec) {
    final surf = AppColors.surf(context);
    final surfH = AppColors.surfH(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(12), border: Border.all(color: surfH)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('LIVE TODAY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
              ]),
              Text('${_todayAttendance.length} CHECK-INS', style: TextStyle(color: sec, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          if (_todayAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('No scans yet today', style: TextStyle(color: sec, fontSize: 12)),
            )
          else ...[
            const SizedBox(height: 12),
            ...(_todayAttendance.take(3).map((r) {
              final user = r['users'] as Map<String, dynamic>?;
              final timeIn = r['time_in'] as String?;
              String time = '';
              if (timeIn != null) {
                try { final dt = DateTime.parse(timeIn).toLocal(); time = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; } catch(_) {}
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Icon(Icons.person, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(user?['name'] ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Text(time, style: TextStyle(color: sec, fontSize: 12)),
                ]),
              );
            }).toList()),
            if (_todayAttendance.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+${_todayAttendance.length - 3} more', style: TextStyle(color: sec, fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFootfall(BuildContext context, List data) {
    final surf = AppColors.surf(context);
    final surfH = AppColors.surfH(context);
    final sec = AppColors.sec(context);

    final maxScans = data.isEmpty ? 1 : data.map((d) => (d['scans'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surf, borderRadius: BorderRadius.circular(12), border: Border.all(color: surfH)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map<Widget>((d) {
          final scans = (d['scans'] as num?)?.toInt() ?? 0;
          final ratio = maxScans > 0 ? scans / maxScans : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(scans.toString(), style: TextStyle(fontSize: 9, color: sec, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  height: 60 * ratio + 4,
                  decoration: BoxDecoration(
                    color: ratio > 0.6 ? AppColors.primary : surfH,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(d['day']?.toString() ?? '', style: TextStyle(fontSize: 8, color: sec)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
