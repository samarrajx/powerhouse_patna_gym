import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import 'add_user_screen.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    final res = await ApiService.get('/admin/users');
    if (mounted) {
      setState(() {
        users = res['data'] ?? [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((u) {
      final name = u['name']?.toLowerCase() ?? '';
      final phone = u['phone']?.toLowerCase() ?? '';
      final roll = u['roll_no']?.toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase()) || 
             phone.contains(searchQuery.toLowerCase()) ||
             roll.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('USER MANAGEMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetchUsers, icon: const Icon(Icons.refresh, color: AppColors.secondary)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return InkWell(
                          onTap: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
                            );
                            if (changed == true) _fetchUsers();
                          },
                          child: _buildUserCard(user),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
          if (added == true) _fetchUsers();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Color(0xFF3F4041)),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = user['status'] ?? 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceHigh,
            child: Text(user['name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user['phone'] ?? 'No phone', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: status == 'active' ? Colors.green : Colors.red),
                ),
              ),
              const SizedBox(height: 4),
              Text(user['membership_plan'] ?? 'Standard', style: const TextStyle(fontSize: 10, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
