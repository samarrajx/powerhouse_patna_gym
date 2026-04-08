import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../auth/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildSection(
              context,
              'PREFERENCES',
              [
                _buildTile(
                  context,
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'ACCOUNT',
              [
                _buildTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                _buildTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _DocViewScreen(title: 'PRIVACY POLICY'))),
                ),
                _buildTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _DocViewScreen(title: 'TERMS OF SERVICE'))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'DANGER ZONE',
              [
                _buildTile(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.error,
                  onTap: () {
                    _showLogoutSync(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'PH GYM v1.2.0',
              style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.text3(context),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfHigh(context)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap, Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.text1(context),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDim) => AlertDialog(
          backgroundColor: AppColors.surf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('CHANGE PASSWORD'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 12),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: TextStyle(color: AppColors.text3(context)))),
            TextButton(
              onPressed: loading ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                setDim(() => loading = true);
                final res = await ref.read(authProvider.notifier).changePassword(oldCtrl.text, newCtrl.text);
                if (context.mounted) {
                   setDim(() => loading = false);
                   if (res == true) {
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password')));
                   }
                }
              },
              child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutSync(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('LOGOUT'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: TextStyle(color: AppColors.text3(context)))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('LOGOUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DocViewScreen extends StatelessWidget {
  final String title;
  const _DocViewScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: April 2026',
              style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (title == 'PRIVACY POLICY') ...[
              _docHeading(context, '1. Information We Collect'),
              _docBody(context,
                  'Power House Gym collects your name, phone number, date of birth, address, and membership details when you register. Attendance records are captured automatically via QR scan each time you enter the facility.'),
              _docHeading(context, '2. How We Use Your Information'),
              _docBody(context,
                  'Your data is used solely to manage your membership, track attendance, send renewal reminders, and communicate gym schedule updates. We do not sell or share your personal information with third parties.'),
              _docHeading(context, '3. Push Notifications'),
              _docBody(context,
                  'With your permission, we may send push notifications for attendance confirmations, membership expiry reminders, and gym announcements. You can disable notifications at any time from your device settings.'),
              _docHeading(context, '4. Data Retention'),
              _docBody(context,
                  'Your data is retained for the duration of your active membership plus one year. You may request deletion of your account data by contacting the gym administration.'),
              _docHeading(context, '5. Security'),
              _docBody(context,
                  'All data is stored on secured cloud infrastructure (Supabase). Passwords are hashed and never stored in plain text. Access tokens expire automatically for your protection.'),
              _docHeading(context, '6. Contact'),
              _docBody(context,
                  'For any privacy-related queries, contact Power House Gym management at the front desk or via the registered gym phone number.'),
            ] else ...[
              _docHeading(context, '1. Membership'),
              _docBody(context,
                  'By registering at Power House Gym you agree to abide by the gym\'s rules and code of conduct. Membership is personal and non-transferable. Misuse may result in suspension or termination without refund.'),
              _docHeading(context, '2. Attendance & Access'),
              _docBody(context,
                  'Entry is permitted only via QR code scan. Members must carry their registered phone or present their QR code at the entry station. Tailgating or sharing access is strictly prohibited.'),
              _docHeading(context, '3. Fees & Renewals'),
              _docBody(context,
                  'Membership fees are due on or before the renewal date. The gym reserves the right to freeze access upon expiry. No pro-rated refunds are issued for unused days unless otherwise agreed in writing.'),
              _docHeading(context, '4. Health & Safety'),
              _docBody(context,
                  'Members must disclose any medical conditions that may affect their ability to exercise safely. Power House Gym is not liable for injuries resulting from improper use of equipment or failure to follow staff instructions.'),
              _docHeading(context, '5. Facility Rules'),
              _docBody(context,
                  'Members must wear appropriate footwear at all times. Re-rack weights after use. Maintain hygiene standards. Food and glass containers are not permitted on the gym floor.'),
              _docHeading(context, '6. Amendments'),
              _docBody(context,
                  'Power House Gym reserves the right to amend these terms at any time. Continued use of the facility constitutes acceptance of updated terms.'),
            ],
            const SizedBox(height: 16),
            Text(
              '© 2026 Power House Gym, Patna. All rights reserved.',
              style: TextStyle(color: AppColors.text3(context), fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(0).copyWith(top: 20, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.text1(context),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _docBody(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(color: AppColors.text2(context), fontSize: 14, height: 1.6),
    );
  }
}
