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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('MEMBERS'),
        actions: [
          IconButton(
            onPressed: _fetchUsers, 
            icon: Icon(Icons.refresh, color: AppColors.text3(context), size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, phone or roll...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
                              );
                              if (changed == true) _fetchUsers();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: _buildUserCard(user),
                          ),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = (user['status'] ?? 'active').toString().toLowerCase();
    final isActive = status == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user['name']?[0]?.toUpperCase() ?? '?', 
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['name'] ?? 'UNKNOWN').toString().toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
                ),
                const SizedBox(height: 2),
                Text(
                  user['phone'] ?? 'NO PHONE', 
                  style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8, 
                    fontWeight: FontWeight.w900, 
                    color: isActive ? AppColors.success : AppColors.error,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (user['membership_plan'] ?? 'BASIC').toString().toUpperCase(), 
                style: TextStyle(fontSize: 10, color: AppColors.text3(context), fontWeight: FontWeight.w800, letterSpacing: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
