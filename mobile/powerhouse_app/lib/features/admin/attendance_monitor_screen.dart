import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class AttendanceMonitorScreen extends ConsumerStatefulWidget {
  const AttendanceMonitorScreen({super.key});

  @override
  ConsumerState<AttendanceMonitorScreen> createState() => _AttendanceMonitorScreenState();
}

class _AttendanceMonitorScreenState extends ConsumerState<AttendanceMonitorScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await ApiService.get('/admin/attendance/today');
    if (mounted) {
      if (res['success'] == true) {
        setState(() { _records = res['data'] ?? []; _isLoading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Failed'; _isLoading = false; });
      }
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TODAY\'S', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const Text('ATTENDANCE', style: TextStyle(color: AppColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${_records.length} IN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildError()
                      : _records.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _fetch,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _records.length,
                                itemBuilder: (ctx, i) => _buildTile(_records[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetch,
        backgroundColor: AppColors.surfaceHigh,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
        label: const Text('REFRESH', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> r) {
    final user = r['users'] as Map<String, dynamic>?;
    final name = user?['name'] ?? 'Unknown';
    final roll = user?['roll_no'] ?? '';
    final timeIn = _formatTime(r['time_in']);
    final timeOut = r['time_out'] != null ? _formatTime(r['time_out']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(19)),
            child: const Icon(Icons.person, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface, fontSize: 14)),
                if (roll.isNotEmpty)
                  Text(roll, style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.login, size: 11, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(timeIn, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              ]),
              if (timeOut != null)
                Row(children: [
                  const Icon(Icons.logout, size: 11, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(timeOut, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                ])
              else
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('INSIDE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.how_to_reg, color: AppColors.surfaceHigh, size: 56),
        const SizedBox(height: 16),
        const Text('NO SCANS YET TODAY', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh, size: 16), label: const Text('REFRESH')),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
      const SizedBox(height: 12),
      Text(_error!),
      TextButton(onPressed: _fetch, child: const Text('RETRY')),
    ]));
  }
}
