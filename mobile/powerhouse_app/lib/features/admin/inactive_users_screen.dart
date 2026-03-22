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
  final Set<String> _restoringIds = {};

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
        title: const Text('RESTORE MEMBER'),
        content: Text('Are you sure you want to restore "${name.toUpperCase()}" to active status?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('RESTORE', style: TextStyle(color: Colors.white)),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member restored successfully'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Restoration failed'), backgroundColor: AppColors.error));
      }
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '—';
    try { 
      final dt = DateTime.parse(d); 
      const m = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']; 
      return '${dt.day} ${m[dt.month-1]} ${dt.year}'; 
    } catch(_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('INACTIVE MEMBERS'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : _users.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _buildInactiveUserCard(_users[i]),
                      ),
                    ),
    );
  }

  Widget _buildInactiveUserCard(Map<String, dynamic> u) {
    final id = u['id'].toString();
    final name = (u['name'] ?? 'UNKNOWN').toString().toUpperCase();
    final status = (u['status'] ?? 'inactive').toString().toLowerCase();
    final isRestoring = _restoringIds.contains(id);
    final phone = u['phone'] ?? 'NO PHONE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surf(context), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.surfHigh(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_off, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)),
                Text(phone, style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (status == 'grace' ? Colors.orange : AppColors.error).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(), 
                        style: TextStyle(color: status == 'grace' ? Colors.orange : AppColors.error, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('EXPIRED: ${_formatDate(u['membership_expiry'])}', style: TextStyle(color: AppColors.text3(context).withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isRestoring
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : TextButton(
                  onPressed: () => _restore(id, name),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('RESTORE', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified_user_outlined, color: AppColors.text3(context).withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text('ALL MEMBERS ACTIVE', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 8),
        Text('No members are currently suspended or expired', style: TextStyle(color: AppColors.text3(context).withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
      const SizedBox(height: 16),
      Text(_error!, style: TextStyle(color: AppColors.text2(context), fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _fetch, child: const Text('RETRY')),
    ]));
  }
}
