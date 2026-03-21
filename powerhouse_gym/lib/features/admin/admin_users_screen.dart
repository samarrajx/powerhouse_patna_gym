import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/dio_client.dart';

final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await apiCall(dio.get('/admin/users'));
  if (res['success'] == true) return res['data'] ?? [];
  return [];
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Members', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.lime,
        foregroundColor: const Color(0xFF0E0E0E),
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.lime)),
              error: (e, _) => Center(child: Text('Error loading users\n$e', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))),
              data: (list) {
                final filtered = list.where((u) {
                  final name = (u['name'] ?? '').toLowerCase();
                  final phone = (u['phone'] ?? '').toLowerCase();
                  return name.contains(_query) || phone.contains(_query);
                }).toList();
                return RefreshIndicator(
                  color: AppTheme.lime,
                  onRefresh: () => ref.refresh(adminUsersProvider.future),
                  child: filtered.isEmpty
                      ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final u = filtered[i] as Map;
                            final status = u['status'] ?? 'active';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.lime.withOpacity(0.15),
                                  child: Text((u['name'] ?? 'U').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: AppTheme.lime, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(u['phone'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'active' ? AppTheme.lime.withOpacity(0.12) : AppTheme.coral.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold,
                                      color: status == 'active' ? AppTheme.lime : AppTheme.coral,
                                    )),
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Member', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 14),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final res = await apiCall(dio.post('/admin/users/onboard', data: {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'password': 'samgym',
                  }));
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(adminUsersProvider);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['message'] ?? 'Done'),
                    backgroundColor: res['success'] == true ? Colors.green : AppTheme.coral,
                  ));
                },
                child: const Text('CREATE MEMBER'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
