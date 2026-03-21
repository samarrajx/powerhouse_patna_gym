import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/dio_client.dart';

final todayAttendanceAdminProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await apiCall(dio.get('/admin/attendance/today'));
  if (res['success'] == true) return res['data'] ?? [];
  return [];
});

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(todayAttendanceAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Attendance", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin')),
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.lime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.coral))),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No check-ins today yet', style: TextStyle(color: Colors.grey)))
            : RefreshIndicator(
                color: AppTheme.lime,
                onRefresh: () => ref.refresh(todayAttendanceAdminProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final r = list[i] as Map;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.lime.withOpacity(0.1),
                            child: Text(
                              (r['users']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppTheme.lime, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['users']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                'In: ${_time(r['time_in'])}  •  Out: ${_time(r['time_out'])}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ]),
                          ),
                          Icon(r['time_out'] != null ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: r['time_out'] != null ? AppTheme.lime : Colors.grey, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  String _time(dynamic iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return '--:--'; }
  }
}
