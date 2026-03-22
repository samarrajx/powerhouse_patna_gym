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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('ATTENDANCE'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR RECORDS', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  if (!_isLoading && _records.isNotEmpty)
                    Text('You have ${_records.length} sessions recorded', style: TextStyle(color: AppColors.text2(context), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfHigh(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasCheckout ? AppColors.primaryDim : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasCheckout ? Icons.check_circle_outline : Icons.flash_on,
              color: hasCheckout ? AppColors.primary : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatTime(timeIn), style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600)),
                    if (hasCheckout) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('→', style: TextStyle(color: AppColors.text3(context).withOpacity(0.5), fontSize: 12)),
                      ),
                      Text(_formatTime(timeOut), style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600)),
                    ] else ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
                Text('${dur.inHours}h ${dur.inMinutes % 60}m', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13)),
                Text('SESSION', style: TextStyle(color: AppColors.text3(context), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
          Icon(Icons.history_toggle_off, color: AppColors.text3(context).withOpacity(0.3), size: 64),
          const SizedBox(height: 16),
          Text('NO SESSIONS YET', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Scan the QR to start your journey', style: TextStyle(color: AppColors.text3(context).withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: AppColors.text2(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchHistory, 
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}
