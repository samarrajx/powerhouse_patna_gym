import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../auth/auth_provider.dart';
import '../admin/user_management_screen.dart';
import '../admin/qr_generator_screen.dart';
import '../admin/add_user_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final res = await ApiService.get('/admin/dashboard');
    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          stats = res['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ADMIN COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.secondary, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 32),
              const Text('QUICK ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: AppColors.secondary)),
              const SizedBox(height: 16),
              _buildActionGrid(),
              const SizedBox(height: 32),
              _buildLiveMonitorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 4 : 2;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: width > 600 ? 2.0 : 1.5,
      children: [
        _buildStatTile('TOTAL USERS', stats?['total_users']?.toString() ?? '...', Icons.people_outline),
        _buildStatTile('TODAY ATTENDANCE', stats?['today_attendance']?.toString() ?? '...', Icons.how_to_reg),
        _buildStatTile('INACTIVE', stats?['inactive_users']?.toString() ?? '...', Icons.person_off_outlined),
        _buildStatTile('EXPIRING SOON', stats?['expiring_soon']?.toString() ?? '...', Icons.timer_outlined),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
              Text(label, style: const TextStyle(fontSize: 8, color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {'label': 'ONBOARD', 'icon': Icons.person_add_outlined, 'screen': const AddUserScreen()},
      {'label': 'ADMIN QR', 'icon': Icons.qr_code, 'screen': const QRGeneratorScreen()},
      {'label': 'MEMBERS', 'icon': Icons.group_outlined, 'screen': const UserManagementScreen()},
      {'label': 'HISTORY', 'icon': Icons.history, 'screen': const UserManagementScreen()},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => _buildActionIcon(
        a['label'] as String, 
        a['icon'] as IconData,
        () => Navigator.push(context, MaterialPageRoute(builder: (context) => a['screen'] as Widget)),
      )).toList(),
    );
  }

  Widget _buildActionIcon(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildLiveMonitorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.live_tv, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Text('LIVE MONITOR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('VIEW ALL', style: TextStyle(fontSize: 10))),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('No active scans in the last 15 min', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
