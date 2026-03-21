import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.coral)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.lime.withOpacity(0.2),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.lime),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.lime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (user?.role ?? 'user').toUpperCase(),
                style: const TextStyle(color: AppTheme.lime, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Details
            _InfoCard(items: [
              _InfoItem(icon: Icons.phone, label: 'Phone', value: user?.phone ?? ''),
              _InfoItem(icon: Icons.group, label: 'Batch', value: user?.batchName ?? 'N/A'),
              _InfoItem(icon: Icons.card_membership, label: 'Membership', value: user?.membershipPlan ?? 'Standard'),
              _InfoItem(icon: Icons.calendar_today, label: 'Expires', value: user?.membershipExpiry ?? 'N/A'),
              _InfoItem(icon: Icons.circle, label: 'Status', value: user?.status?.toUpperCase() ?? 'ACTIVE'),
            ]),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock_outline, color: AppTheme.lime),
              label: const Text('Change Password', style: TextStyle(color: AppTheme.lime)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.lime),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label, value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(item.icon, color: Colors.grey, size: 18),
                    const SizedBox(width: 14),
                    Text(item.label, style: const TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Text(item.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (!isLast) Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}
