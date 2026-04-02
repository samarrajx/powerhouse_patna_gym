import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/ui/app_card.dart';
import 'package:intl/intl.dart';
import '../admin/attendance_monitor_screen.dart';
import '../admin/add_user_screen.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notification_center.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.jpg', width: 34, height: 34, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            const Text('PH GYM ADMIN'),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(notificationsProvider).maybeWhen(
                data: (list) => list.where((n) => !n.isRead).length,
                orElse: () => 0,
              );
              return Stack(
                children: [
                   IconButton(
                    icon: const Icon(Icons.notifications_none_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen())),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
             await _fetchAll();
             await ref.read(notificationsProvider.notifier).fetchNotifications();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('SYSTEM OVERVIEW', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('COMMAND CENTER', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28, letterSpacing: -0.5)),
                const SizedBox(height: 32),
                _buildStatsGrid(context),
                const SizedBox(height: 32),
                Text('QUICK ACTIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: AppColors.text3(context))),
                const SizedBox(height: 14),
                _buildActionGrid(context),
                const SizedBox(height: 32),
                _buildLiveMonitor(context),
                const SizedBox(height: 32),
                if (stats?['weekly_footfall'] != null) ...[
                   Text('WEEKLY FOOTFALL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: AppColors.text3(context))),
                   const SizedBox(height: 14),
                   _buildFootfall(context, stats!['weekly_footfall'] as List),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final tiles = [
      {'label': 'TOTAL MEMBERS', 'value': stats?['total_users']?.toString() ?? '0', 'icon': Icons.people_outline, 'color': AppColors.blue},
      {'label': 'TODAY CHECK-INS', 'value': stats?['today_attendance']?.toString() ?? '0', 'icon': Icons.how_to_reg, 'color': AppColors.success},
      {'label': 'INACTIVE ACCOUNTS', 'value': stats?['inactive_users']?.toString() ?? '0', 'icon': Icons.person_off_outlined, 'color': AppColors.error},
      {'label': 'EXPIRING SOON', 'value': stats?['expiring_soon']?.toString() ?? '0', 'icon': Icons.timer_outlined, 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15, // Increased from 1.4 for more vertical space
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final t = tiles[i];
        final Color c = t['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfHigh(context)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(t['icon'] as IconData, color: c, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['value'] as String, 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  Text(
                    t['label'] as String, 
                    style: TextStyle(fontSize: 9, color: AppColors.text3(context), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      {'label': 'NEW MEMBER', 'icon': Icons.person_add_alt_1_outlined, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())).then((_) => _fetchAll())},
      {'label': 'VIEW MONITOR', 'icon': Icons.monitor_heart_outlined, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceMonitorScreen()))},
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: GestureDetector(
          onTap: a['onTap'] as VoidCallback,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surf(context), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfHigh(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryDim, shape: BoxShape.circle),
                  child: Icon(a['icon'] as IconData, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(a['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildLiveMonitor(BuildContext context) {
    return AppCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 10, height: 10, 
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 4)]),
          ),
          title: const Text('LIVE ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 13)),
          subtitle: Text('${_todayAttendance.length} CHECK-INS TODAY', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          children: [
            const Divider(height: 24),
            if (_todayAttendance.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Awaiting first scan of the day...', style: TextStyle(color: AppColors.text3(context), fontSize: 13, fontWeight: FontWeight.w600))),
              )
            else ...[
              ...(_todayAttendance.take(8).map((r) {
                final user = r['users'] as Map<String, dynamic>?;
                final timeIn = r['time_in'] as String?;
                String time = '--:--';
                if (timeIn != null) {
                  try { final dt = DateTime.parse(timeIn).toLocal(); time = DateFormat('hh:mm a').format(dt); } catch(_) {}
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(user?['name']?.toString().toUpperCase() ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                    Text(time, style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900)),
                  ]),
                );
              }).toList()),
              if (_todayAttendance.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('View more in Attendance Monitor', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFootfall(BuildContext context, List data) {
    final maxScans = data.isEmpty ? 1 : data.map((d) => (d['scans'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map<Widget>((d) {
              final scans = (d['scans'] as num?)?.toInt() ?? 0;
              final ratio = maxScans > 0 ? scans / maxScans : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(scans.toString(), style: TextStyle(fontSize: 10, color: AppColors.text3(context), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Container(
                      height: 80 * ratio + 4,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: AppColors.primaryGlow.withOpacity(0.1), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(d['day']?.toString().substring(0, 3).toUpperCase() ?? '', style: TextStyle(fontSize: 9, color: AppColors.text3(context), fontWeight: FontWeight.w800)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
