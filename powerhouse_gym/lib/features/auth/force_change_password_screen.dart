import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/network/dio_client.dart';

class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  const ForceChangePasswordScreen({super.key});
  @override
  ConsumerState<ForceChangePasswordScreen> createState() => _FCPState();
}

class _FCPState extends ConsumerState<ForceChangePasswordScreen> {
  final _curr = TextEditingController(text: 'samgym');
  final _new  = TextEditingController();
  final _conf = TextEditingController();
  bool _loading = false, _o1 = true, _o2 = true;
  String? _error;

  Future<void> _submit() async {
    if (_new.text.length < 6) { setState(() => _error = 'Password must be at least 6 characters'); return; }
    if (_new.text != _conf.text) { setState(() => _error = 'Passwords do not match'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await apiCall(dio.post('/auth/change-password', data: { 'oldPassword': _curr.text, 'newPassword': _new.text }));
      // Update auth state so must_change_password is no longer true
      await ref.read(authProvider.notifier).refreshUser();
    } catch(e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.7), radius: 1.4,
            colors: [AppColors.lime.withOpacity(0.08), Theme.of(context).scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 52, height: 52, decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: AppColors.coral, size: 26),
                ),
                const SizedBox(height: 22),
                Text('Change Your Password', style: GoogleFonts.spaceGrotesk(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('For your security, please change your default password before continuing.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14, height: 1.5)),
                const SizedBox(height: 32),

                // Warning banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.coral.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('You cannot skip this step. Your account security is important.', style: TextStyle(color: AppColors.coral, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.coral.withOpacity(0.25))),
                    child: Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13))),
                  const SizedBox(height: 12),
                ],

                GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(children: [
                    TextField(controller: _curr, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _new, obscureText: _o1,
                      decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.lock_open_outlined),
                        suffixIcon: IconButton(icon: Icon(_o1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: () => setState(() => _o1 = !_o1))),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _conf, obscureText: _o2,
                      decoration: InputDecoration(labelText: 'Confirm New Password', prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(icon: Icon(_o2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: () => setState(() => _o2 = !_o2))),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                      : Text('SET NEW PASSWORD', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('Sign Out', style: TextStyle(color: AppColors.coral)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
