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
      backgroundColor: isError ? AppColors.error : AppColors.darkSurfHigh,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('PROFILE'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemberCard(user),
              const SizedBox(height: 32),

              _buildSection(context, 'MEMBERSHIP', [
                _buildTile(context, 'Plan', user?['membership_plan'] ?? 'STANDARD'),
                _buildTile(context, 'Expires', _formatDate(user?['membership_expiry'])),
                _buildTile(context, 'Fees Status', (user?['fees_status'] ?? 'PAID').toString().toUpperCase(), color: AppColors.success),
              ]),
              const SizedBox(height: 24),

              _buildSection(context, 'CONTACT INFORMATION', [
                _buildTile(context, 'Phone', user?['phone'] ?? '—'),
                if (user?['phone_alt'] != null) _buildTile(context, 'Alt Phone', user?['phone_alt']),
                _buildTile(context, 'Father / Guardian', user?['father_name'] ?? '—'),
                _buildTile(context, 'Address', user?['address'] ?? '—'),
              ]),
              const SizedBox(height: 24),

              _buildSection(context, 'GYM RECORD', [
                _buildTile(context, 'Roll No', user?['roll_no']?.toString() ?? '—'),
                _buildTile(context, 'Joined', _formatDate(user?['date_of_joining'])),
                _buildTile(context, 'Body Type', user?['body_type'] ?? 'ATHLETIC'),
              ]),
              const SizedBox(height: 32),

              _buildPasswordSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic>? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGlow.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['name']?.toString().toUpperCase() ?? 'MEMBER',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  user?['role']?.toString().toUpperCase() ?? 'GYM MEMBER',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
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
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.text3(context), fontSize: 13, fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.text1(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surf(context), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.surfHigh(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _changingPwd = !_changingPwd),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('SECURITY & PASSWORD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                  Icon(_changingPwd ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_changingPwd) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPwdField('Current Password', _oldPwdCtrl, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                  const SizedBox(height: 16),
                  _buildPwdField('New Password', _newPwdCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 16),
                  _buildPwdField('Confirm New Password', _confirmPwdCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _pwdLoading ? null : _changePassword,
                    child: _pwdLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('UPDATE PASSWORD'),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
          onPressed: toggle,
        ),
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
