import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return [];
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
        _snack('Attendance record saved successfully');
        setState(() { _selectedUser = null; _timeIn = null; _timeOut = null; _date = DateTime.now(); });
      } else {
        _snack(res['message'] ?? 'Failed to save record', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('MANUAL ENTRY'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('SELECT MEMBER'),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              _buildSelectedMemberCard()
            else
              _buildMemberSearchField(),
            const SizedBox(height: 32),

            _buildSectionLabel('SESSION LOGS'),
            const SizedBox(height: 12),
            _buildDatePicker('TARGET DATE', _date, (d) => setState(() => _date = d)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTimePicker('TIME IN', _timeIn, (t) => setState(() => _timeIn = t))),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('TIME OUT', _timeOut, (t) => setState(() => _timeOut = t))),
              ],
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryGlow.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SAVE RECORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSelectedMemberCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((_selectedUser!['name'] ?? '').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(_selectedUser!['phone'] ?? '', style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.primary), 
            onPressed: () => setState(() => _selectedUser = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSearchField() {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search by name, phone or roll...',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.surf(context), 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: AppColors.surfHigh(context)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredUsers.length,
              itemBuilder: (_, i) {
                final u = _filteredUsers[i];
                return ListTile(
                  dense: true,
                  title: Text((u['name'] ?? '').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  subtitle: Text(u['phone'] ?? '', style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w600)),
                  onTap: () => setState(() { _selectedUser = u; _searchQuery = ''; }),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onPick) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
        if (t != null) onPick(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time != null ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}' : '--:--', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: time != null ? AppColors.text1(context) : AppColors.text3(context))),
            const Icon(Icons.access_time, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
