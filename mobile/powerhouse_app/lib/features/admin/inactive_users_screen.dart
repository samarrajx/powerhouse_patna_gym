import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class InactiveUsersScreen extends ConsumerStatefulWidget {
  const InactiveUsersScreen({super.key});

  @override
  ConsumerState<InactiveUsersScreen> createState() => _InactiveUsersScreenState();
}

class _InactiveUsersScreenState extends ConsumerState<InactiveUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  Set<String> _restoringIds = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await ApiService.get('/admin/users/inactive');
    if (mounted) {
      if (res['success'] == true) {
        setState(() { _users = res['data'] ?? []; _isLoading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Failed'; _isLoading = false; });
      }
    }
  }

  Future<void> _restore(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('RESTORE MEMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text('Restore "$name" to active status?', style: const TextStyle(color: AppColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('RESTORE', style: TextStyle(color: Colors.green))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _restoringIds.add(id));
    final res = await ApiService.post('/admin/users/$id/restore', {});
    if (mounted) {
      setState(() => _restoringIds.remove(id));
      if (res['success'] == true) {
        setState(() => _users.removeWhere((u) => u['id'].toString() == id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member restored to active'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    try { final dt = DateTime.parse(d); const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${dt.day} ${m[dt.month-1]} ${dt.year}'; } catch(_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('INACTIVE MEMBERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!),
                  TextButton(onPressed: _fetch, child: const Text('RETRY')),
                ]))
              : _users.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.group_off, color: AppColors.surfaceHigh, size: 56),
                      const SizedBox(height: 16),
                      const Text('ALL MEMBERS ACTIVE', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _buildTile(_users[i]),
                      ),
                    ),
    );
  }

  Widget _buildTile(Map<String, dynamic> u) {
    final id = u['id'].toString();
    final name = u['name'] ?? 'Unknown';
    final status = u['status'] ?? 'inactive';
    final isRestoring = _restoringIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.person_off, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              Text(u['phone'] ?? '', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'grace' ? Colors.orange.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: status == 'grace' ? Colors.orange : AppColors.error, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('Expired: ${_formatDate(u['membership_expiry'])}', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          isRestoring
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : TextButton(
                  onPressed: () => _restore(id, name),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('RESTORE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}
