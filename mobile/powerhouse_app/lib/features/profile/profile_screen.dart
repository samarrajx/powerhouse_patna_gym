import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _changingPwd = false;
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _pwdLoading = false;
  bool _obscureOld = true, _obscureNew = true, _obscureConfirm = true;

  @override
  void dispose() {
    _oldPwdCtrl.dispose(); _newPwdCtrl.dispose(); _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      _showSnack('Passwords do not match', isError: true); return;
    }
    if (_newPwdCtrl.text.length < 6) {
      _showSnack('Minimum 6 characters', isError: true); return;
    }
    setState(() => _pwdLoading = true);
    final res = await ApiService.post('/auth/change-password', {
      'oldPassword': _oldPwdCtrl.text,
      'newPassword': _newPwdCtrl.text,
    });
    if (mounted) {
      setState(() => _pwdLoading = false);
      if (res['success'] == true) {
        _showSnack('Password changed successfully');
        setState(() => _changingPwd = false);
        _oldPwdCtrl.clear(); _newPwdCtrl.clear(); _confirmPwdCtrl.clear();
      } else {
        _showSnack(res['message'] ?? 'Failed', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.surfaceHigh,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () { Navigator.pop(context); ref.read(authProvider.notifier).logout(); },
            child: const Text('LOGOUT', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('MY', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text('PROFILE', style: TextStyle(color: AppColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),

              // Avatar + Name
              _buildMemberCard(user),
              const SizedBox(height: 20),

              // Info tiles
              _buildSection('MEMBERSHIP', [
                _buildTile('Plan', user?['membership_plan'] ?? '—'),
                _buildTile('Expires', _formatDate(user?['membership_expiry'])),
                _buildTile('Fees Status', user?['fees_status']?.toString().toUpperCase() ?? '—'),
              ]),
              const SizedBox(height: 16),
              _buildSection('CONTACT', [
                _buildTile('Phone', user?['phone'] ?? '—'),
                if (user?['phone_alt'] != null) _buildTile('Alt Phone', user?['phone_alt']),
                _buildTile('Father / Guardian', user?['father_name'] ?? '—'),
                _buildTile('Address', user?['address'] ?? '—'),
              ]),
              const SizedBox(height: 16),
              _buildSection('GYM INFO', [
                _buildTile('Roll No', user?['roll_no'] ?? '—'),
                _buildTile('Joined', _formatDate(user?['date_of_joining'])),
                _buildTile('Body Type', user?['body_type'] ?? '—'),
              ]),
              const SizedBox(height: 24),

              // Change Password
              _buildPasswordSection(),
              const SizedBox(height: 16),

              // Logout
              GestureDetector(
                onTap: _confirmLogout,
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.metallicGradient, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: const Color(0xFF3F4041), borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?['name']?.toString().toUpperCase() ?? '—',
                    style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 2),
                Text(user?['role']?.toString().toUpperCase() ?? 'MEMBER',
                    style: const TextStyle(color: Color(0xFF3F4041), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 12))),
          Expanded(flex: 3, child: Text(value ?? '—', style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _changingPwd = !_changingPwd),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('CHANGE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5))),
                  Icon(_changingPwd ? Icons.expand_less : Icons.expand_more, color: AppColors.secondary),
                ],
              ),
            ),
          ),
          if (_changingPwd) ...[
            const Divider(height: 1, color: AppColors.surfaceHigh),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPwdField('Current Password', _oldPwdCtrl, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                  const SizedBox(height: 12),
                  _buildPwdField('New Password', _newPwdCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _buildPwdField('Confirm New Password', _confirmPwdCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pwdLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _pwdLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Text('UPDATE PASSWORD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPwdField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 12),
        filled: true, fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.secondary, size: 18), onPressed: toggle),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '—';
    try {
      final dt = DateTime.parse(date);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return date; }
  }
}
