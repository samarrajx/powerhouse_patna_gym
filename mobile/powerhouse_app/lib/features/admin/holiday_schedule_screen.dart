import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

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
        backgroundColor: AppColors.surface,
        title: const Text('ADD HOLIDAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)), builder: (c,child)=>Theme(data:ThemeData.dark(),child:child!));
              if (d != null) setS(() => picked = d);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(picked != null ? '${picked!.day}/${picked!.month}/${picked!.year}' : 'Select Date', style: const TextStyle(color: AppColors.onSurface)),
              ]),
            ),
          ),
          TextField(
            controller: reasonCtrl,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Reason (e.g. Diwali)',
              hintStyle: const TextStyle(color: AppColors.secondary),
              filled: true, fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              if (picked == null || reasonCtrl.text.isEmpty) return;
              final date = '${picked!.year}-${picked!.month.toString().padLeft(2,'0')}-${picked!.day.toString().padLeft(2,'0')}';
              await ApiService.post('/schedule/holidays', {'date': date, 'reason': reasonCtrl.text});
              if (mounted) { Navigator.pop(ctx); _fetchHolidays(); }
            },
            child: const Text('ADD', style: TextStyle(color: AppColors.primary)),
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
        backgroundColor: AppColors.surface,
        title: Text((day['day_of_week'] as String? ?? '').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Open: ', style: TextStyle(color: AppColors.secondary)),
            Switch(value: isOpen, onChanged: (v) => setS(() => isOpen = v), activeColor: AppColors.primary),
          ]),
          if (isOpen) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: openCtrl, style: const TextStyle(color: AppColors.onSurface), decoration: InputDecoration(labelText: 'Open', labelStyle: const TextStyle(color: AppColors.secondary), filled: true, fillColor: AppColors.surfaceHigh, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: closeCtrl, style: const TextStyle(color: AppColors.onSurface), decoration: InputDecoration(labelText: 'Close', labelStyle: const TextStyle(color: AppColors.secondary), filled: true, fillColor: AppColors.surfaceHigh, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
            ]),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ApiService.put('/schedule/weekly/${day['day_of_week']}', {'is_open': isOpen, 'open_time': openCtrl.text, 'close_time': closeCtrl.text});
              if (mounted) { Navigator.pop(ctx); _fetchSchedule(); }
            },
            child: const Text('SAVE', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('HOLIDAY & SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          tabs: const [Tab(text: 'HOLIDAYS'), Tab(text: 'SCHEDULE')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildHolidaysTab(),
        _buildScheduleTab(),
      ]),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _addHolidayDialog,
                backgroundColor: AppColors.surfaceHigh,
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('ADD HOLIDAY', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHolidaysTab() {
    if (_holidayLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_holidays.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.celebration, color: AppColors.surfaceHigh, size: 52),
      const SizedBox(height: 12),
      const Text('No holidays set', style: TextStyle(color: AppColors.secondary)),
      const SizedBox(height: 80),
    ]));
    return RefreshIndicator(
      onRefresh: _fetchHolidays,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _holidays.length,
        itemBuilder: (_, i) {
          final h = _holidays[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
            child: Row(children: [
              const Icon(Icons.event_busy, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(h['reason'] ?? '', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ])),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _deleteHoliday(h['id'].toString()),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_scheduleLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _schedule.length,
      itemBuilder: (_, i) {
        final d = _schedule[i];
        final isOpen = d['is_open'] ?? true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceHigh)),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: isOpen ? Colors.green.withValues(alpha: 0.1) : AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
              child: Icon(isOpen ? Icons.check : Icons.close, color: isOpen ? Colors.green : AppColors.secondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((d['day_of_week'] as String? ?? '').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(isOpen ? '${d['open_time']} — ${d['close_time']}' : 'CLOSED', style: TextStyle(color: isOpen ? AppColors.secondary : AppColors.error, fontSize: 12)),
            ])),
            IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 18), onPressed: () => _editScheduleDialog(d)),
          ]),
        );
      },
    );
  }
}
