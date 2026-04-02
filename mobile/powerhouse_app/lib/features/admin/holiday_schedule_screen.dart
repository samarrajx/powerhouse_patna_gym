import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/utils/date_utils.dart';

class HolidayScheduleScreen extends ConsumerStatefulWidget {
  const HolidayScheduleScreen({super.key});

  @override
  ConsumerState<HolidayScheduleScreen> createState() => _HolidayScheduleScreenState();
}

class _HolidayScheduleScreenState extends ConsumerState<HolidayScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _holidays = [];
  List<dynamic> _schedule = [];
  List<dynamic> _batches = [];
  bool _holidayLoading = true;
  bool _scheduleLoading = true;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHolidays();
    _fetchSchedule();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _fetchHolidays() async {
    setState(() => _holidayLoading = true);
    final res = await ApiService.get('/schedule/holidays');
    if (mounted) setState(() { _holidays = res['data'] ?? []; _holidayLoading = false; });
  }

  Future<void> _fetchSchedule() async {
    setState(() => _scheduleLoading = true);
    final res = await ApiService.get('/schedule/weekly');
    final batchRes = await ApiService.get('/schedule/batches');
    if (mounted) setState(() { 
      _schedule = res['data'] ?? []; 
      _batches = batchRes['data'] ?? [];
      _scheduleLoading = false; 
      _isDirty = false;
    });
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);
    final res = await ApiService.post('/schedule/bulk-update', {
      'weekly': _schedule,
      'batches': _batches,
    });
    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ALL CHANGES SAVED! 🚀')));
        _fetchSchedule();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SAVE FAILED: ${res['message']}')));
      }
    }
  }

  Future<void> _deleteHoliday(String id) async {
    final res = await ApiService.delete('/schedule/holidays/$id');
    if (res['success'] == true) _fetchHolidays();
  }

  Future<void> _addHolidayDialog() async {
    DateTime? picked;
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: const Text('ADD GYM HOLIDAY'),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx, 
                  initialDate: GymDateUtils.getNowIST(), 
                  firstDate: GymDateUtils.getNowIST().subtract(const Duration(days: 30)), 
                  lastDate: GymDateUtils.getNowIST().add(const Duration(days: 365)),
                );
                if (d != null) setS(() => picked = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'DATE'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(picked != null ? '${picked!.day}/${picked!.month}/${picked!.year}' : 'Select Date', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'REASON EX: DIWALI'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (picked == null || reasonCtrl.text.isEmpty) return;
              final date = '${picked!.year}-${picked!.month.toString().padLeft(2,'0')}-${picked!.day.toString().padLeft(2,'0')}';
              await ApiService.post('/schedule/holidays', {'date': date, 'reason': reasonCtrl.text});
              if (mounted) { Navigator.pop(ctx); _fetchHolidays(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Future<void> _editDayDialog(int index) async {
    final day = _schedule[index];
    bool isOpen = day['is_open'] ?? true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: Text((day['day_of_week'] as String? ?? '').toUpperCase()),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GYM STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Switch(value: isOpen, onChanged: (v) => setS(() => isOpen = v), activeColor: AppColors.primary),
              ],
            ),
            Text(isOpen ? 'GYM IS OPEN' : 'GYM IS CLOSED', style: TextStyle(color: isOpen ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _schedule[index]['is_open'] = isOpen;
                _isDirty = true;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('UPDATE', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Future<void> _editBatchDialog(int index) async {
    final batch = _batches[index];
    bool active = batch['is_active'] ?? true;
    final startCtrl = TextEditingController(text: (batch['start_time'] as String?)?.substring(0,5) ?? '05:00');
    final endCtrl = TextEditingController(text: (batch['end_time'] as String?)?.substring(0,5) ?? '22:00');

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: Text((batch['name'] as String? ?? '').toUpperCase()),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BATCH STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Switch(value: active, onChanged: (v) => setS(() => active = v), activeColor: AppColors.primary),
              ],
            ),
            Text(active ? 'BATCH IS ACTIVE' : 'BATCH IS CLOSED', style: TextStyle(color: active ? AppColors.success : AppColors.error, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            if (active) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'START'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'END'))),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _batches[index]['is_active'] = active;
                _batches[index]['start_time'] = startCtrl.text;
                _batches[index]['end_time'] = endCtrl.text;
                _isDirty = true;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('UPDATE', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('GYM OPERATIONS'),
        actions: [
          if (_tabController.index == 1 && _isDirty)
            TextButton(
              onPressed: _isSaving ? null : _saveAllChanges,
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('SAVE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [Tab(text: 'HOLIDAYS'), Tab(text: 'TIMINGS / BATCHES')],
        ),
      ),
      body: TabBarView(
        controller: _tabController, 
        children: [
          _buildHolidaysTab(),
          _buildScheduleTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton(
                heroTag: 'add_holiday_fab',
                onPressed: _addHolidayDialog,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : _isDirty ? FloatingActionButton.extended(
                heroTag: 'save_schedule_fab',
                onPressed: _isSaving ? null : _saveAllChanges,
                label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                icon: const Icon(Icons.save, color: Colors.white),
              ) : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHolidaysTab() {
    if (_holidayLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_holidays.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.celebration, color: AppColors.text3(context).withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text('NO UPCOMING HOLIDAYS', style: TextStyle(color: AppColors.text3(context), fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _fetchHolidays,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _holidays.length,
        itemBuilder: (_, i) {
          final h = _holidays[i];
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_busy, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text((h['reason'] ?? 'HOLIDAY').toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(h['date'] ?? '', style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _deleteHoliday(h['id'].toString()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_scheduleLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(
      onRefresh: _fetchSchedule,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionHeader('GYM BATCHES', 'Enable/disable slots or adjust timings'),
          const SizedBox(height: 16),
          ..._batches.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            final active = b['is_active'] ?? true;
            return _buildOperationItem(
              title: b['name']?.toString().toUpperCase() ?? 'BATCH',
              subtitle: active ? '${b['start_time'].toString().substring(0,5)} to ${b['end_time'].toString().substring(0,5)}' : 'BATCH CLOSED',
              active: active,
              onTap: () => _editBatchDialog(i),
            );
          }),
          const SizedBox(height: 32),
          _buildSectionHeader('OPERATING DAYS', 'Weekly gym availability'),
          const SizedBox(height: 16),
          ..._schedule.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final isOpen = d['is_open'] ?? true;
            return _buildOperationItem(
              title: d['day_of_week']?.toString().toUpperCase() ?? '',
              subtitle: isOpen ? 'GYM OPEN' : 'GYM CLOSED',
              active: isOpen,
              onTap: () => _editDayDialog(i),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildOperationItem({required String title, required String subtitle, required bool active, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surf(context), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: active ? AppColors.surfHigh(context) : AppColors.error.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (active ? AppColors.success : AppColors.error).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(active ? Icons.check_circle_outline : Icons.block, color: active ? AppColors.success : AppColors.error, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: active ? AppColors.text3(context) : AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: AppColors.text3(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
