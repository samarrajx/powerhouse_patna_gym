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
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool joining) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: joining ? _dateOfJoining : _membershipExpiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('ONBOARD MEMBER'),
      ),
      body: _isLoading && _batches.isEmpty ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('PERSONAL INFORMATION'),
              const SizedBox(height: 12),
              _buildField('FULL NAME *', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('PHONE NUMBER *', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('ALT PHONE', _phoneAltController, Icons.contact_phone_outlined, keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('FATHER\'S NAME', _fatherNameController, Icons.family_restroom_outlined),
              
              const SizedBox(height: 32),
              _buildSectionLabel('MEMBERSHIP SETTINGS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDatePicker('JOINING DATE', _dateOfJoining, () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('EXPIRY DATE', _membershipExpiry, () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildBatchDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('BODY TYPE', _bodyType, ['skinny', 'normal', 'fatty'], (v) => setState(() => _bodyType = v!))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown('PLAN', _membershipPlan, ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual'], (v) => setState(() => _membershipPlan = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('FEES STATUS', _feesStatus, ['paid', 'pending'], (v) => setState(() => _feesStatus = v!))),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionLabel('ADDITIONAL DETAILS'),
              const SizedBox(height: 12),
              _buildField('ROLL NO (OPTIONAL)', _rollNoController, Icons.numbers_outlined),
              const SizedBox(height: 16),
              _buildField('ADDRESS', _addressController, Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _buildField('INTERNAL NOTES', _notesController, Icons.note_add_outlined, maxLines: 3),
              
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
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, 
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CREATE MEMBER ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: (v) => (label.contains('*') && v!.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBatchId,
      decoration: const InputDecoration(labelText: 'BATCH'),
      hint: const Text('Select Batch'),
      items: _batches.map((b) => DropdownMenuItem(value: b['id'] as String, child: Text((b['name'] ?? '???').toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) => setState(() => _selectedBatchId = v),
    );
  }
}
