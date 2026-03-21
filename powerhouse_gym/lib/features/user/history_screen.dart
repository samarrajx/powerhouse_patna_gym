import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/dio_client.dart';

final attendanceHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await apiCall(dio.get('/attendance/history'));
  if (res['success'] == true) return res['data'] ?? [];
  return [];
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(attendanceHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance History', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.lime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.coral))),
        data: (records) => records.isEmpty
            ? const Center(child: Text('No attendance records yet', style: TextStyle(color: Colors.grey)))
            : RefreshIndicator(
                color: AppTheme.lime,
                onRefresh: () => ref.refresh(attendanceHistoryProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i] as Map;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.lime.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today, color: AppTheme.lime, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('In: ${r['time_in'] ?? '--'}  •  Out: ${r['time_out'] ?? '--'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: r['status'] == 'present' ? AppTheme.lime.withOpacity(0.15) : AppTheme.coral.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (r['status'] ?? 'present').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold,
                                color: r['status'] == 'present' ? AppTheme.lime : AppTheme.coral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
