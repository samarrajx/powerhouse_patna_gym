import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/ui/design_system.dart';
import '../../core/ui/app_card.dart';
import 'notifications_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('ALERTS & NOTICES'),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.text3(context)),
                  const SizedBox(height: 16),
                  Text('NO NOTIFICATIONS YET', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final n = list[index];
                return _buildNotificationTile(context, ref, n);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WidgetRef ref, NotificationModel n) {
    IconData icon = Icons.notifications_outlined;
    Color color = AppColors.primary;

    final titleLower = n.title.toLowerCase();
    final msgLower = n.message.toLowerCase();

    if (titleLower.contains('holiday') || titleLower.contains('closed') || titleLower.contains('schedule') ||
        msgLower.contains('holiday') || msgLower.contains('closed') || msgLower.contains('schedule')) {
      icon = Icons.calendar_today_outlined;
      color = Colors.blue;
    } else if (titleLower.contains('timing') || titleLower.contains('batch') || titleLower.contains('reschedule') ||
               msgLower.contains('timing') || msgLower.contains('batch') || msgLower.contains('reschedule')) {
      icon = Icons.access_time_outlined;
      color = Colors.orange;
    } else if (n.type == 'offer') {
      icon = Icons.local_offer_outlined;
      color = Colors.green;
    } else if (n.type == 'urgent') {
      icon = Icons.error_outline;
      color = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            if (!n.isRead) ref.read(notificationsProvider.notifier).markAsRead(n.id);
            _showDetails(context, n);
          },
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                AppSpacing.s16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n.title.toUpperCase(),
                              style: TextStyle(
                                color: AppColors.text1(context),
                                fontSize: 13,
                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.text2(context), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('dd MMM | HH:mm').format(n.createdAt),
                        style: TextStyle(color: AppColors.text3(context).withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, NotificationModel n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(n.type.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(DateFormat('dd MMM yyyy').format(n.createdAt), style: TextStyle(color: AppColors.text3(context), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            Text(n.title, style: TextStyle(color: AppColors.text1(context), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(n.message, style: TextStyle(color: AppColors.text2(context), fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('DISMISS'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
