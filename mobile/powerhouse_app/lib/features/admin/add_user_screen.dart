import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneAltController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _dateOfJoining = DateTime.now();
  DateTime _membershipExpiry = DateTime.now().add(const Duration(days: 30));
  
  String _membershipPlan = 'Monthly';
  String _bodyType = 'normal';
  String? _selectedBatchId;
  String _feesStatus = 'paid';
  
  List<Map<String, dynamic>> _batches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/admin/batches');
      if (mounted) {
        if (res['success'] == true) {
          final List<dynamic> data = res['data'];
          setState(() {
            _batches = data.map((e) => e as Map<String, dynamic>).toList();
            if (_batches.isNotEmpty) {
              _selectedBatchId = _batches.first['id'];
            }
          });
        } else {
          _useFallbackBatches();
        }
      }
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      if (mounted) _useFallbackBatches();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useFallbackBatches() {
    setState(() {
      _batches = [
        {'id': '0515f242-095a-4cae-8e5e-78d5780bbf99', 'name': 'Morning Batch'},
        {'id': '74115ffe-6b7b-4071-96cc-f6a5cb4937f9', 'name': 'Evening Batch'},
      ];
      _selectedBatchId = _batches.first['id'];
    });
  }

  Future<void> _selectDate(BuildContext context, bool joining) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: joining ? _dateOfJoining : _membershipExpiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (joining) {
          _dateOfJoining = picked;
        } else {
          _membershipExpiry = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/admin/users/onboard', {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'phone_alt': _phoneAltController.text.isEmpty ? null : _phoneAltController.text,
        'roll_no': _rollNoController.text.isEmpty ? null : _rollNoController.text,
        'address': _addressController.text.isEmpty ? null : _addressController.text,
        'father_name': _fatherNameController.text.isEmpty ? null : _fatherNameController.text,
        'date_of_joining': DateFormat('yyyy-MM-dd').format(_dateOfJoining),
        'body_type': _bodyType,
        'batch_id': _selectedBatchId,
        'membership_plan': _membershipPlan,
        'membership_expiry': DateFormat('yyyy-MM-dd').format(_membershipExpiry),
        'fees_status': _feesStatus,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member onboarded successfully!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to onboard member')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NEW MEMBER ONBOARDING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading && _batches.isEmpty ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('FULL NAME *', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildField('PHONE NUMBER *', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('ALT PHONE (OPTIONAL)', _phoneAltController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('ROLL NO (OPTIONAL)', _rollNoController, Icons.numbers_outlined),
              const SizedBox(height: 20),
              _buildField('FATHER\'S NAME', _fatherNameController, Icons.family_restroom_outlined),
              const SizedBox(height: 20),
              _buildField('ADDRESS', _addressController, Icons.home_outlined),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildDatePicker('JOINING DATE', _dateOfJoining, () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('MEMBERSHIP EXPIRY', _membershipExpiry, () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildBatchDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('BODY TYPE', _bodyType, ['skinny', 'normal', 'fatty'], (v) => setState(() => _bodyType = v!))),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildDropdown('PLAN', _membershipPlan, ['Standard', 'Monthly', 'Quarterly', 'Semi-Annual', 'Annual'], (v) => setState(() => _membershipPlan = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('FEES STATUS', _feesStatus, ['paid', 'pending'], (v) => setState(() => _feesStatus = v!))),
                ],
              ),
              const SizedBox(height: 20),

              _buildField('NOTES (OPTIONAL)', _notesController, Icons.note_add_outlined, maxLines: 3),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.metallicGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Color(0xFF3F4041))
                      : const Text('ONBOARD MEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
          validator: (v) => (label.contains('*') && v!.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.surface,
          items: items.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBatchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BATCH', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedBatchId,
          dropdownColor: AppColors.surface,
          items: _batches.map((b) => DropdownMenuItem(value: b['id'] as String, child: Text(b['name'] ?? 'Unknown'))).toList(),
          onChanged: (v) => setState(() => _selectedBatchId = v),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }
}
