import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../auth/auth_provider.dart';
import '../qr/qr_scanner_screen.dart';

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
    final user = ref.watch(authProvider).user;
    final isOpen = gymStatus?['is_open'] ?? false;

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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStatus,
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
                _buildStatusCard(isOpen, gymStatus?['schedule']),
                const SizedBox(height: 24),
                _buildMembershipCard(user),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: AppColors.text3(context))),
                    GestureDetector(
                      onTap: () {
                        // Navigate to history tab logic would go here
                      },
                      child: const Text('VIEW ALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary, letterSpacing: 1)),
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
