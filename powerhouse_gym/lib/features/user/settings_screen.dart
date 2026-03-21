import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/network/dio_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _old  = TextEditingController();
  final _new  = TextEditingController();
  final _conf = TextEditingController();
  bool _changing = false;
  String? _error, _success;

  Future<void> _changePassword() async {
    if (_new.text.length < 6) { setState(() => _error = 'Min 6 characters'); return; }
    if (_new.text != _conf.text) { setState(() => _error = 'Passwords don\'t match'); return; }
    setState(() { _changing = true; _error = null; _success = null; });
    try {
      await apiCall(dio.post('/auth/change-password', data: { 'oldPassword': _old.text, 'newPassword': _new.text }));
      _old.clear(); _new.clear(); _conf.clear();
      if (mounted) setState(() { _success = 'Password changed successfully!'; _changing = false; });
    } catch(e) {
      if (mounted) setState(() { _error = e.toString(); _changing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [
              isDark ? const Color(0xFF0E120A) : const Color(0xFFE8F0FF),
              isDark ? AppColors.darkBg : AppColors.lightBg,
              isDark ? const Color(0xFF080C14) : const Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Profile tile
                GlassCard(
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.lime, Color(0xFF8AC800)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppColors.limeGlow, blurRadius: 14)],
                      ),
                      alignment: Alignment.center,
                      child: Text((user?.name ?? 'U')[0].toUpperCase(), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.name ?? 'User', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 17)),
                      Text(user?.role?.toUpperCase() ?? 'MEMBER', style: TextStyle(color: AppColors.lime, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      if (user?.phone != null) Text(user!.phone!, style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace')),
                    ])),
                  ]),
                ),

                const SizedBox(height: 16),

                // Theme toggle
                GlassCard(
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.blue, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(isDark ? 'Dark Mode' : 'Light Mode', style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12)),
                    ])),
                    Switch(
                      value: !isDark,
                      activeColor: AppColors.lime,
                      activeTrackColor: AppColors.lime.withOpacity(0.25),
                      inactiveThumbColor: cs.onSurface.withOpacity(0.4),
                      inactiveTrackColor: cs.onSurface.withOpacity(0.1),
                      onChanged: (_) => themeNotifier.toggle(),
                    ),
                    const SizedBox(width: 4),
                    Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 18)),
                  ]),
                ),

                const SizedBox(height: 16),

                // Change password
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.lime.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.lock_outline, color: AppColors.lime, size: 17)),
                      const SizedBox(width: 10),
                      const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                    const SizedBox(height: 18),
                    if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.coral.withOpacity(0.25))), child: Text(_error!, style: const TextStyle(color: AppColors.coral, fontSize: 13)))),
                    if (_success != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.lime.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.lime.withOpacity(0.25))), child: Text(_success!, style: const TextStyle(color: AppColors.lime, fontSize: 13)))),
                    TextField(controller: _old,  obscureText: true, decoration: const InputDecoration(labelText: 'Current Password',  prefixIcon: Icon(Icons.lock_outline))),
                    const SizedBox(height: 12),
                    TextField(controller: _new,  obscureText: true, decoration: const InputDecoration(labelText: 'New Password',       prefixIcon: Icon(Icons.lock_open_outlined))),
                    const SizedBox(height: 12),
                    TextField(controller: _conf, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password',   prefixIcon: Icon(Icons.check_circle_outline))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: _changing ? null : _changePassword,
                        child: _changing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                          : const Text('UPDATE PASSWORD'),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // Sign out
                GlassCard(
                  onTap: () => ref.read(authProvider.notifier).logout(),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 20)),
                    const SizedBox(width: 14),
                    const Text('Sign Out', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.coral.withOpacity(0.5), size: 18),
                  ]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
