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
  bool _holidayLoading = true;
  bool _scheduleLoading = true;

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
    if (mounted) setState(() { _schedule = res['data'] ?? []; _scheduleLoading = false; });
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

  Future<void> _editScheduleDialog(Map<String, dynamic> day) async {
    bool isOpen = day['is_open'] ?? true;
    final openCtrl = TextEditingController(text: day['open_time'] ?? '05:00');
    final closeCtrl = TextEditingController(text: day['close_time'] ?? '22:00');
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
            if (isOpen) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: openCtrl, decoration: const InputDecoration(labelText: 'OPENING'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: closeCtrl, decoration: const InputDecoration(labelText: 'CLOSING'))),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.put('/schedule/weekly/${day['day_of_week']}', {'is_open': isOpen, 'open_time': openCtrl.text, 'close_time': closeCtrl.text});
              if (mounted) { Navigator.pop(ctx); _fetchSchedule(); }
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
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [Tab(text: 'HOLIDAYS'), Tab(text: 'TIMINGS')],
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
                onPressed: _addHolidayDialog,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : const SizedBox.shrink(),
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _schedule.length,
        itemBuilder: (_, i) {
          final d = _schedule[i];
          final isOpen = d['is_open'] ?? true;
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
                  decoration: BoxDecoration(
                    color: (isOpen ? AppColors.success : AppColors.error).withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isOpen ? Icons.check_circle_outline : Icons.block, color: isOpen ? AppColors.success : AppColors.error, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text((d['day_of_week'] as String? ?? '').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(isOpen ? '${d['open_time']} to ${d['close_time']}' : 'GYM IS CLOSED', style: TextStyle(color: isOpen ? AppColors.text3(context) : AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppColors.text3(context), size: 20), 
                  onPressed: () => _editScheduleDialog(d),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
