import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key});

  @override
  ConsumerState<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends ConsumerState<ManualAttendanceScreen> {
  List<dynamic> _users = [];
  Map<String, dynamic>? _selectedUser;
  DateTime _date = DateTime.now();
  TimeOfDay? _timeIn;
  TimeOfDay? _timeOut;
  bool _loading = false;
  bool _usersLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final res = await ApiService.get('/admin/users');
    if (mounted && res['success'] == true) {
      setState(() { _users = res['data'] ?? []; _usersLoading = false; });
    } else {
      setState(() => _usersLoading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) =>
      (u['name'] as String? ?? '').toLowerCase().contains(q) ||
      (u['phone'] as String? ?? '').contains(q) ||
      (u['roll_no'] as String? ?? '').toLowerCase().contains(q)
    ).toList();
  }

  String _isoDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String? _buildTimeIso(TimeOfDay? t) {
    if (t == null) return null;
    final now = DateTime.now();
    return DateTime(_date.year, _date.month, _date.day, t.hour, t.minute).toIso8601String();
  }

  Future<void> _submit() async {
    if (_selectedUser == null) { _snack('Please select a member', isError: true); return; }
    setState(() => _loading = true);
    final res = await ApiService.post('/admin/attendance/manual', {
      'user_id': _selectedUser!['id'],
      'date': _isoDate(_date),
      if (_timeIn != null) 'time_in': _buildTimeIso(_timeIn),
      if (_timeOut != null) 'time_out': _buildTimeIso(_timeOut),
    });
    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        _snack('Attendance saved');
        setState(() { _selectedUser = null; _timeIn = null; _timeOut = null; _date = DateTime.now(); });
      } else {
        _snack(res['message'] ?? 'Failed', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.surfaceHigh,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('MANUAL ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member picker
            const Text('SELECT MEMBER', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            if (_selectedUser != null)
              _buildSelectedMember()
            else
              _buildMemberSearch(),
            const SizedBox(height: 24),

            // Date picker
            const Text('DATE', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 12),
                    Text(_isoDate(_date), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time pickers
            Row(
              children: [
                Expanded(child: _buildTimePicker('CHECK IN', _timeIn, (t) => setState(() => _timeIn = t))),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePicker('CHECK OUT', _timeOut, (t) => setState(() => _timeOut = t))),
              ],
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Text('SAVE ATTENDANCE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMember() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedUser!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_selectedUser!['phone'] ?? '', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.secondary), onPressed: () => setState(() => _selectedUser = null)),
        ],
      ),
    );
  }

  Widget _buildMemberSearch() {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name, phone or roll no...',
            hintStyle: const TextStyle(color: AppColors.secondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.secondary, size: 20),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        if (_usersLoading)
          const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary))
        else if (_searchQuery.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredUsers.length,
              itemBuilder: (_, i) {
                final u = _filteredUsers[i];
                return ListTile(
                  leading: const Icon(Icons.person, color: AppColors.secondary, size: 20),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontSize: 14)),
                  subtitle: Text(u['phone'] ?? '', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                  onTap: () => setState(() { _selectedUser = u; _searchQuery = ''; }),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now(), builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!));
            if (t != null) onPick(t);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
            child: Row(children: [
              const Icon(Icons.access_time, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text(time != null ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}' : 'Tap to set',
                  style: TextStyle(color: time != null ? AppColors.onSurface : AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
          ),
        ),
      ],
    );
  }
}
