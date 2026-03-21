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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('MORE', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text('ADMIN TOOLS', style: TextStyle(color: AppColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 28),

              const Text('ATTENDANCE', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              _buildTile(context, 'Manual Attendance Entry', 'Add or edit attendance records', Icons.edit_calendar, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualAttendanceScreen()))),
              const SizedBox(height: 24),

              const Text('GYM CONTROL', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              _buildTile(context, 'Holiday & Schedule', 'Manage holidays and opening hours', Icons.event_note, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayScheduleScreen()))),
              const SizedBox(height: 8),

              const SizedBox(height: 24),
              const Text('MEMBER MANAGEMENT', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              _buildTile(context, 'Inactive Members', 'View and restore inactive accounts', Icons.person_off_outlined, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InactiveUsersScreen()))),
              const SizedBox(height: 8),
              _buildTile(context, 'Onboard New Member', 'Register a new gym member', Icons.person_add_outlined, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()))),

              const SizedBox(height: 40),
              // Theme toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    Icon(Icons.brightness_6_outlined, color: Theme.of(context).colorScheme.secondary, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('DARK THEME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Consumer(builder: (ctx, ref2, _) {
                      final isDark = ref2.watch(themeProvider) == ThemeMode.dark;
                      return Switch(value: isDark, onChanged: (_) => ref2.read(themeProvider.notifier).toggleTheme());
                    }),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.secondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                      TextButton(onPressed: () { Navigator.pop(context); ref.read(authProvider.notifier).logout(); }, child: const Text('LOGOUT', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('LOGOUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}
