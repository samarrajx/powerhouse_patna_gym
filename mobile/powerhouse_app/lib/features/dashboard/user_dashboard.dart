import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/ui/design_system.dart';
import '../../core/ui/app_card.dart';
import '../../core/theme/rank_theme.dart';
import '../auth/auth_provider.dart';
import '../qr/qr_scanner_screen.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notification_center.dart';
import 'leaderboard_screen.dart';

class DailyActivity {
  final String day;
  final double durationHours;
  final DateTime date;

  DailyActivity({required this.day, required this.durationHours, required this.date});
}

class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard> {
  Map<String, dynamic>? gymStatus;
  bool isLoading = true;

  List<dynamic> _recentActivity = [];
  List<DailyActivity> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    final res = await ApiService.get('/attendance/history');
    if (mounted && res['success'] == true) {
      final history = res['data'] as List;
      setState(() {
        _recentActivity = history.take(3).toList();
        _weeklyStats = _processWeeklyStats(history);
      });
    }
  }

  List<DailyActivity> _processWeeklyStats(List<dynamic> history) {
    final List<DailyActivity> stats = [];
    final now = DateTime.now();
    
    // Generate last 7 days including today
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Find history for this date
      final record = history.firstWhere(
        (entry) => (entry['date'] as String).startsWith(dateStr), 
        orElse: () => null
      );
      
      double duration = 0;
      if (record != null && record['time_in'] != null && record['time_out'] != null) {
        try {
          final tIn = DateTime.parse(record['time_in']);
          final tOut = DateTime.parse(record['time_out']);
          duration = tOut.difference(tIn).inMinutes / 60.0;
        } catch (_) {}
      }
      
      stats.add(DailyActivity(
        day: DateFormat('E').format(date).toUpperCase(),
        durationHours: duration.clamp(0, 5), // Max 5 hours for visual scale
        date: date,
      ));
    }
    return stats;
  }

  Future<void> _fetchStatus() async {
    final res = await ApiService.get('/gym/status');
    if (mounted) {
      setState(() {
        gymStatus = res['data'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isOpen = gymStatus?['is_open'] ?? false;

    if (authState.comebackEligible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showComebackPopup(ref);
      });
    }

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
            const Text('PH GYM'),
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
            await _fetchStatus();
            await _fetchActivity();
            await ref.read(notificationsProvider.notifier).fetchNotifications();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.s16,
                _buildStatusBar(isOpen, user?['current_streak'] ?? 0, _getUpdatedTierInfo(user?['current_streak'] ?? 0)['rank']),
                AppSpacing.s24,
                if (gymStatus?['is_holiday'] == true) ...[
                  _buildHolidayBanner(gymStatus?['holiday_reason']),
                  AppSpacing.s24,
                ],
                _buildHeader(user?['name'] ?? 'MEMBER'),
                AppSpacing.s24,
                _buildStreakCard(user),
                AppSpacing.s24,
                _buildStatusCard(isOpen, gymStatus?['schedule']),
                AppSpacing.s24,
                _buildActivityGraph(),
                AppSpacing.s24,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: AppColors.text3(context))),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                      icon: const Icon(Icons.leaderboard_outlined, size: 14),
                      label: const Text('RANKINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                AppSpacing.s12,
                _buildActivityList(),
                const SizedBox(height: 120), // Bottom padding
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCheckInButton(),
    );
  }

  Widget _buildStatusBar(bool isOpen, int streak, String rank) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            isOpen ? 'OPEN' : 'CLOSED',
            isOpen ? Icons.check_circle_outline : Icons.lock_outline,
            isOpen ? AppColors.success : AppColors.error,
          ),
          _buildVerticalDivider(),
          _buildStatusItem(
            '$streak DAYS',
            Icons.local_fire_department_outlined,
            AppColors.primary,
          ),
          _buildVerticalDivider(),
          _buildStatusItem(
            'RANK $rank',
            Icons.military_tech_outlined,
            RankTheme.getRankColor(rank),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 16, width: 1, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildHolidayBanner(String? reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GYM CLOSED TODAY', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 12)),
                if (reason != null && reason.isNotEmpty)
                  Text(reason.toUpperCase(), style: TextStyle(color: AppColors.error.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WELCOME BACK,', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(name.toUpperCase(), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24, letterSpacing: -0.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isOpen, Map<String, dynamic>? schedule) {
    final batches = gymStatus?['batches'] as Map<String, dynamic>?;
    final morning = batches?['morning'] as Map<String, dynamic>?;
    final evening = batches?['evening'] as Map<String, dynamic>?;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.p12),
            decoration: BoxDecoration(
              color: (isOpen ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Icon(
              isOpen ? Icons.door_front_door : Icons.door_back_door,
              color: isOpen ? AppColors.success : AppColors.error,
              size: 28,
            ),
          ),
          AppSpacing.s16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'GYM IS OPEN' : 'GYM IS CLOSED',
                  style: TextStyle(fontWeight: FontWeight.w900, color: isOpen ? AppColors.success : AppColors.error, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                if (schedule != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Window: ${schedule['open_time']} - ${schedule['close_time']}',
                        style: TextStyle(color: AppColors.text3(context), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Morning ${morning?['start_time'] ?? '--:--'}-${morning?['end_time'] ?? '--:--'} · Evening ${evening?['start_time'] ?? '--:--'}-${evening?['end_time'] ?? '--:--'}',
                        style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                else
                   Text('Consult staff for timings', style: TextStyle(color: AppColors.text3(context), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic>? user) {
    final streak = user?['current_streak'] ?? 0;
    final tier = _getUpdatedTierInfo(streak);
    final color = RankTheme.getRankColor(tier['rank']);

    return AppCard(
      child: Row(
        children: [
          _buildStreakCircle(streak, color),
          AppSpacing.s16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tier['name'].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                    Text('RANK ${tier['rank']}', style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
                AppSpacing.s12,
                _buildProgressBar(streak, tier['nextGoal'], color),
                AppSpacing.s8,
                Text('$streak DAYS IN A ROW', style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getUpdatedTierInfo(int streak) {
    if (streak <= 3) return {'name': 'Iron', 'rank': 'E', 'nextGoal': 4};
    if (streak <= 10) return {'name': 'Bronze', 'rank': 'D', 'nextGoal': 11};
    if (streak <= 20) return {'name': 'Silver', 'rank': 'C', 'nextGoal': 21};
    if (streak <= 35) return {'name': 'Gold', 'rank': 'B', 'nextGoal': 36};
    if (streak <= 50) return {'name': 'Platinum', 'rank': 'A', 'nextGoal': 51};
    return {'name': 'Legendary', 'rank': 'S', 'nextGoal': 100};
  }

  Widget _buildStreakCircle(int streak, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            value: (streak % 10) / 10,
            strokeWidth: 6,
            color: color,
            backgroundColor: color.withOpacity(0.1),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$streak', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const Text('DAYS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(int current, int next, Color color) {
    final progress = (current % next) / next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.1, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: color,
          ),
        ),
        AppSpacing.s8,
        Text('${next - (current % next)} DAYS TO NEXT TIER', style: TextStyle(color: AppColors.text3(context), fontSize: 9, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _showComebackPopup(WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              const Text(
                'WELCOME BACK!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                'We missed you! As a welcome back gift, we\'ve added 2 bonus days to your membership.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(authProvider.notifier).claimComeback();
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bonus claimed! 2 days added.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                  ),
                  child: const Text('CLAIM MY GIFT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityGraph() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEEKLY ACTIVITY', style: TextStyle(color: AppColors.text3(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  const Text('DURATIONS (HRS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('7ndays', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: _weeklyStats.isEmpty 
              ? const Center(child: CircularProgressIndicator()) 
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < _weeklyStats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(_weeklyStats[index].day, style: TextStyle(color: AppColors.text3(context), fontSize: 9, fontWeight: FontWeight.w900)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _weeklyStats.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.durationHours,
                            gradient: AppColors.primaryGradient,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 5,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_recentActivity.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfHigh(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: AppColors.text3(context), size: 32),
              const SizedBox(height: 8),
              Text('No sessions yet today', style: TextStyle(color: AppColors.text3(context), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _recentActivity.asMap().entries.map((entry) {
        final r = entry.value;
        final date = r['date'] as String? ?? '';
        final timeIn = r['time_in'] as String?;
        String label = 'Session Logged';
        if (timeIn != null) {
          try {
            final dt = DateTime.parse(timeIn).toLocal();
            label = 'Checked in at ${dt.hour.toString().padLeft(2,"0")}:${dt.minute.toString().padLeft(2,"0")}';
          } catch (_) {}
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surf(context), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfHigh(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(date, style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              )),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckInButton() {
    return Container(
      width: 220,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGlow.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text('SCAN QR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

extension DateTimeFormat on DateTime {
  String toLocaleDateString() {
    return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year}";
  }
}
