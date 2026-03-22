import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../auth/auth_provider.dart';
import 'manual_attendance_screen.dart';
import 'holiday_schedule_screen.dart';
import 'inactive_users_screen.dart';
import 'add_user_screen.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('ADMIN TOOLS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(context, 'ATTENDANCE MANAGEMENT'),
              const SizedBox(height: 12),
              _buildTile(
                context, 
                'Manual Entry', 
                'Add or edit attendance records', 
                Icons.edit_calendar_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualAttendanceScreen())),
              ),
              const SizedBox(height: 32),

              _buildSectionLabel(context, 'GYM OPERATIONS'),
              const SizedBox(height: 12),
              _buildTile(
                context, 
                'Holiday & Schedule', 
                'Manage gym timing and holidays', 
                Icons.event_available_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayScheduleScreen())),
              ),
              const SizedBox(height: 32),

              _buildSectionLabel(context, 'MEMBER CONTROLS'),
              const SizedBox(height: 12),
              _buildTile(
                context, 
                'Inactive Members', 
                'Manage suspended accounts', 
                Icons.person_off_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InactiveUsersScreen())),
              ),
              const SizedBox(height: 12),
              _buildTile(
                context, 
                'Register Member', 
                'Onboard a new gym member', 
                Icons.person_add_alt_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
              ),

              const SizedBox(height: 48),
              
              // Settings & System
              _buildSectionLabel(context, 'SYSTEM SETTINGS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfHigh(context)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.brightness_6_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('DARK THEME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                          Consumer(builder: (ctx, ref2, _) {
                            final isDark = ref2.watch(themeProvider) == ThemeMode.dark;
                            return Switch(
                              value: isDark, 
                              onChanged: (_) => ref2.read(themeProvider.notifier).toggleTheme(),
                              activeColor: AppColors.primary,
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    InkWell(
                      onTap: () => _showLogoutDialog(context, ref),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.logout, color: AppColors.error, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('SIGN OUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text, 
        style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfHigh(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CONFIRM SIGN OUT'),
        content: const Text('Are you sure you want to log out of the admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () { 
              Navigator.pop(context); 
              ref.read(authProvider.notifier).logout(); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
