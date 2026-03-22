import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../auth/auth_provider.dart';
import '../qr/qr_scanner_screen.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notification_center.dart';
import 'leaderboard_screen.dart';

class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard> {
  Map<String, dynamic>? gymStatus;
  bool isLoading = true;

  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    final res = await ApiService.get('/attendance/history');
    if (mounted && res['success'] == true) {
      setState(() => _recentActivity = (res['data'] as List).take(3).toList());
    }
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
                _buildHeader(user?['name'] ?? 'MEMBER'),
                const SizedBox(height: 32),
                _buildStreakCard(user),
                const SizedBox(height: 24),
                _buildStatusCard(isOpen, gymStatus?['schedule']),
                const SizedBox(height: 24),
                _buildMembershipCard(user),
                const SizedBox(height: 32),
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
                const SizedBox(height: 12),
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

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WELCOME BACK,', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(name.toUpperCase(), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildStatusCard(bool isOpen, Map<String, dynamic>? schedule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfHigh(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOpen ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOpen ? Icons.door_front_door : Icons.door_back_door,
              color: isOpen ? AppColors.success : AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
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
                  Text(
                    'Today: ${schedule['open_time']} - ${schedule['close_time']}',
                    style: TextStyle(color: AppColors.text3(context), fontSize: 13, fontWeight: FontWeight.w600),
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
    final tier = _getTierInfo(streak);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfHigh(context)),
      ),
      child: Row(
        children: [
          _buildStreakCircle(streak, tier['color']),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier['name'].toUpperCase(), style: TextStyle(color: tier['color'], fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('YOUR CURRENT STREAK', style: TextStyle(color: AppColors.text3(context), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildProgressBar(streak, tier['nextGoal']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCircle(int streak, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            value: 0.7, // Visual placeholder
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

  Widget _buildProgressBar(int current, int next) {
    final progress = (current % next) / next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.1, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text('${next - (current % next)} DAYS TO NEXT TIER', style: TextStyle(color: AppColors.text3(context), fontSize: 9, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Map<String, dynamic> _getTierInfo(int streak) {
    if (streak <= 3) return {'name': 'Iron', 'color': Colors.grey, 'nextGoal': 4};
    if (streak <= 10) return {'name': 'Bronze', 'color': Colors.brown, 'nextGoal': 11};
    if (streak <= 20) return {'name': 'Silver', 'color': Colors.blueGrey, 'nextGoal': 21};
    if (streak <= 35) return {'name': 'Gold', 'color': Colors.amber, 'nextGoal': 36};
    if (streak <= 50) return {'name': 'Platinum', 'color': Colors.cyan, 'nextGoal': 51};
    if (streak <= 60) return {'name': 'Diamond', 'color': Colors.blue, 'nextGoal': 61};
    return {'name': 'Legendary', 'color': Colors.redAccent, 'nextGoal': 100};
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

  Widget _buildMembershipCard(Map<String, dynamic>? user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGlow.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.fitness_center, size: 140, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MEMBERSHIP PLAN', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(
                  (user?['membership_plan'] ?? 'STANDARD').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('EXPIRY DATE', user?['membership_expiry'] != null ? 
                      DateTime.parse(user!['membership_expiry']).toLocaleDateString() : 'N/A'),
                    _buildMetric('BATCH', user?['batch_id']?.toString() ?? 'DEFAULT'),
                    _buildMetric('FEE STATUS', (user?['fees_status'] ?? 'PAID').toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
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
        final index = entry.key;
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
