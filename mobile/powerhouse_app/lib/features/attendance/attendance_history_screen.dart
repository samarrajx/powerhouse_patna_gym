import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await ApiService.get('/attendance/history');
    if (mounted) {
      if (res['success'] == true) {
        setState(() { _records = res['data'] ?? []; _isLoading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Failed to load'; _isLoading = false; });
      }
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) { return '--:--'; }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
    } catch (_) { return date; }
  }

  Duration? _duration(String? timeIn, String? timeOut) {
    if (timeIn == null || timeOut == null) return null;
    try {
      return DateTime.parse(timeOut).difference(DateTime.parse(timeIn));
    } catch (_) { return null; }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ATTENDANCE', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Text('YOUR HISTORY', style: TextStyle(color: AppColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  if (!_isLoading && _records.isNotEmpty)
                    Text('${_records.length} sessions recorded', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
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
                              onRefresh: _fetchHistory,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _records.length,
                                itemBuilder: (ctx, i) => _buildRecord(_records[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecord(Map<String, dynamic> r) {
    final date = r['date'] as String?;
    final timeIn = r['time_in'] as String?;
    final timeOut = r['time_out'] as String?;
    final dur = _duration(timeIn, timeOut);
    final hasCheckout = timeOut != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasCheckout ? AppColors.surfaceHigh : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasCheckout ? Icons.check_circle : Icons.radio_button_checked,
              color: hasCheckout ? AppColors.primary : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(_formatTime(timeIn), style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                    if (hasCheckout) ...[
                      const Text('  →  ', style: TextStyle(color: AppColors.surfaceHigh, fontSize: 12)),
                      const Icon(Icons.logout, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(_formatTime(timeOut), style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                    ] else ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dur != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${dur.inHours}h ${dur.inMinutes % 60}m', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                const Text('session', style: TextStyle(color: AppColors.secondary, fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, color: AppColors.surfaceHigh, size: 56),
          const SizedBox(height: 16),
          const Text('NO SESSIONS YET', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Scan the QR to mark your first visit', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.secondary)),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchHistory, child: const Text('RETRY')),
        ],
      ),
    );
  }
}
