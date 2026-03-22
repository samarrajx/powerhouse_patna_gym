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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('LIVE MONITOR'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8, 
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.success, blurRadius: 4)]),
                ),
                const SizedBox(width: 8),
                Text('${_records.length} ACTIVE', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
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
                   Text('TODAY\'S ACTIVITY', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                   const SizedBox(height: 4),
                   Text('REAL-TIME LOGS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
                              onRefresh: _fetch,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _records.length,
                                itemBuilder: (ctx, i) => _buildRecordCard(_records[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetch,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> r) {
    final user = r['users'] as Map<String, dynamic>?;
    final name = (user?['name'] ?? 'UNKNOWN MEMBER').toString().toUpperCase();
    final roll = user?['roll_no'] ?? 'NO ROLL';
    final timeIn = _formatTime(r['time_in']);
    final timeOut = r['time_out'] != null ? _formatTime(r['time_out']) : null;

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
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('ROLL: $roll', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeIn, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15)),
              if (timeOut != null)
                Text('OUT: $timeOut', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w700))
              else
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('INSIDE', style: TextStyle(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        Icon(Icons.history_toggle_off, color: AppColors.text3(context).withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text('NO ACTIVITY YET', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 8),
        Text('Attendance records will appear here as they scan', style: TextStyle(color: AppColors.text3(context).withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
      const SizedBox(height: 16),
      Text(_error!, style: TextStyle(color: AppColors.text2(context), fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _fetch, child: const Text('RETRY')),
    ]));
  }
}
