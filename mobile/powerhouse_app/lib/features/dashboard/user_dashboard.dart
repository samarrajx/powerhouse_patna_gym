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

  @override
  void initState() {
    super.initState();
    _fetchStatus();
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStatus,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(user?['name'] ?? 'MEMBER'),
                    const SizedBox(height: 32),
                    _buildStatusCard(isOpen, gymStatus?['schedule']),
                    const SizedBox(height: 24),
                    _buildMembershipCard(user),
                    const SizedBox(height: 24),
                    const Text('YOUR RECENT ACTIVITY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: AppColors.secondary)),
                    const SizedBox(height: 12),
                    _buildActivityList(),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCheckInButton(),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WELCOME BACK,', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(name.toUpperCase(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onSurface, letterSpacing: -0.5)),
          ],
        ),
        IconButton(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isOpen, Map<String, dynamic>? schedule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.door_front_door : Icons.door_back_door,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'GYM IS OPEN' : 'GYM IS CLOSED',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isOpen ? Colors.green : Colors.red, fontSize: 16),
                ),
                if (schedule != null)
                  Text(
                    'Today: ${schedule['open_time']} - ${schedule['close_time']}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.metallicGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEMBERSHIP STATUS', style: TextStyle(color: Color(0xFF3F4041), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            (user?['membership_plan'] ?? 'STANDARD').toUpperCase(),
            style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('EXPIRY', user?['membership_expiry'] ?? 'N/A'),
              _buildMetric('BATCH', user?['batch_id']?.toString() ?? 'GEN'),
              _buildMetric('STATUS', user?['fees_status'] ?? 'PAID'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF3F4041), fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workout Session', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                    Text('Yesterday, 6:30 PM', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Text('Done', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInButton() {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.metallicGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF3F4041)),
            SizedBox(width: 12),
            Text('CHECK IN', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3F4041), letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}
