import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _userData;
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _phoneAltController;
  late TextEditingController _rollNoController;
  late TextEditingController _addressController;
  late TextEditingController _fatherNameController;
  late TextEditingController _notesController;
  
  late DateTime _dateOfJoining;
  late DateTime _membershipExpiry;
  
  late String _membershipPlan;
  late String _bodyType;
  String? _batchId;
  late String _feesStatus;
  late String _role;

  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _userData = Map.from(widget.user);
    _initControllers();
    _fetchBatches();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _userData['name']);
    _phoneController = TextEditingController(text: _userData['phone']);
    _phoneAltController = TextEditingController(text: _userData['phone_alt']);
    _rollNoController = TextEditingController(text: _userData['roll_no']);
    _addressController = TextEditingController(text: _userData['address']);
    _fatherNameController = TextEditingController(text: _userData['father_name']);
    _notesController = TextEditingController(text: _userData['notes']);
    
    _dateOfJoining = DateTime.tryParse(_userData['date_of_joining'] ?? '') ?? DateTime.now();
    _membershipExpiry = DateTime.tryParse(_userData['membership_expiry'] ?? '') ?? DateTime.now();
    
    _membershipPlan = _userData['membership_plan'] ?? 'Monthly';
    _bodyType = _userData['body_type'] ?? 'normal';
    _batchId = _userData['batch_id'];
    _feesStatus = _userData['fees_status'] ?? 'paid';
    _role = _userData['role'] ?? 'user';
  }

  Future<void> _fetchBatches() async {
    try {
      final res = await ApiService.get('/admin/batches');
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _batches = List<Map<String, dynamic>>.from(res['data']);
          });
        } else {
          _useFallbackBatches();
        }
      }
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      if (mounted) _useFallbackBatches();
    }
  }

  void _useFallbackBatches() {
    setState(() {
      _batches = [
        {'id': '0515f242-095a-4cae-8e5e-78d5780bbf99', 'name': 'Morning Batch'},
        {'id': '74115ffe-6b7b-4071-96cc-f6a5cb4937f9', 'name': 'Evening Batch'},
      ];
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.put('/admin/users/${_userData['id']}', {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'phone_alt': _phoneAltController.text.isEmpty ? null : _phoneAltController.text,
        'roll_no': _rollNoController.text.isEmpty ? null : _rollNoController.text,
        'address': _addressController.text.isEmpty ? null : _addressController.text,
        'father_name': _fatherNameController.text.isEmpty ? null : _fatherNameController.text,
        'date_of_joining': DateFormat('yyyy-MM-dd').format(_dateOfJoining),
        'body_type': _bodyType,
        'batch_id': _batchId,
        'membership_plan': _membershipPlan,
        'membership_expiry': DateFormat('yyyy-MM-dd').format(_membershipExpiry),
        'fees_status': _feesStatus,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'role': _role,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        if (res['success'] == true) {
          setState(() {
            _userData = res['data'];
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Update failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Password?'),
        content: const Text('Password will be reset to "samgym". User must change it on next login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('RESET', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/admin/users/${_userData['id']}/reset-password', {});
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Password reset successfully')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  void _launchWhatsApp() async {
    final name = _userData['name'] ?? 'User';
    final phone = _userData['phone'];
    if (phone == null) return;

    // Get message based on body type template
    String message = "Hi $name, staying consistent is key! Ready for today's workout?";
    if (_bodyType == 'skinny') {
      message = "Hey $name, looking to bulk up? Check out our high-protein diet charts at the reception!";
    } else if (_bodyType == 'fatty') {
      message = "Hey $name, focus on cardio and high reps today for maximum fat burn!";
    }

    final url = "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp. Is it installed?')));
      }
    }
  }

  void _launchCall() async {
    final phone = _userData['phone'];
    if (phone == null) return;
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT MEMBER' : 'MEMBER PROFILE', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit_outlined, color: AppColors.primary))
          else
            IconButton(onPressed: _isLoading ? null : _saveChanges, icon: const Icon(Icons.check, color: Colors.green)),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surfaceHigh,
                      child: Text(_userData['name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.primary, fontSize: 24)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userData['name'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('ID: #${_userData['id'].toString().substring(0, 8)}', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!_isEditing) Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.phone, 'CALL', AppColors.primary, _launchCall)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton(Icons.chat_bubble_outline, 'WHATSAPP', Colors.green, _launchWhatsApp)),
                  const SizedBox(width: 12),
                  _buildIconButton(Icons.lock_reset, 'PWD', AppColors.onSurfaceVariant, _resetPassword),
                ],
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildField('FULL NAME *', _nameController, Icons.person_outline, enabled: _isEditing),
              const SizedBox(height: 20),
              _buildField('PHONE NUMBER *', _phoneController, Icons.phone_android_outlined, enabled: _isEditing, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildField('ALT PHONE', _phoneAltController, Icons.phone_android_outlined, enabled: _isEditing, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildDatePicker('JOINING DATE', _dateOfJoining, _isEditing ? () => _selectDate(context, true) : null)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('EXPIRY DATE', _membershipExpiry, _isEditing ? () => _selectDate(context, false) : null)),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildBatchDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('BODY TYPE', _bodyType, ['skinny', 'normal', 'fatty'], _isEditing ? (v) => setState(() => _bodyType = v!) : null)),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildDropdown('PLAN', _membershipPlan, ['Standard', 'Monthly', 'Quarterly', 'Semi-Annual', 'Annual'], _isEditing ? (v) => setState(() => _membershipPlan = v!) : null)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('ROLE', _role, ['user', 'admin'], _isEditing ? (v) => setState(() => _role = v!) : null)),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildDropdown('FEES STATUS', _feesStatus, ['paid', 'pending'], _isEditing ? (v) => setState(() => _feesStatus = v!) : null),
              const SizedBox(height: 20),

              _buildField('ROLL NO', _rollNoController, Icons.numbers_outlined, enabled: _isEditing),
              const SizedBox(height: 20),
              _buildField('FATHER\'S NAME', _fatherNameController, Icons.family_restroom_outlined, enabled: _isEditing),
              const SizedBox(height: 20),
              _buildField('ADDRESS', _addressController, Icons.home_outlined, enabled: _isEditing),
              const SizedBox(height: 20),
              _buildField('NOTES', _notesController, Icons.note_add_outlined, enabled: _isEditing, maxLines: 3),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
          validator: (v) => (label.contains('*') && v!.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback? onTap) {
    final bool enabled = onTap != null;
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
              border: enabled ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: enabled ? AppColors.primary : AppColors.onSurfaceVariant, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: TextStyle(color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?>? onChanged) {
    final bool enabled = onChanged != null;
    final dropdownItems = items.toSet().toList();
    if (!dropdownItems.contains(value)) {
      dropdownItems.insert(0, value);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.surface,
          style: TextStyle(color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          items: dropdownItems.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBatchDropdown() {
    final bool enabled = _isEditing;
    final currentBatch = _batches.firstWhere((b) => b['id'] == _batchId, orElse: () => {'id': _batchId, 'name': 'Unknown'});
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BATCH', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _batches.any((b) => b['id'] == _batchId) ? _batchId : null,
          dropdownColor: AppColors.surface,
          hint: Text(currentBatch['name'] ?? 'Select Batch', style: TextStyle(color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant)),
          items: _batches.map((b) => DropdownMenuItem(value: b['id'] as String, child: Text(b['name'] ?? 'Unknown'))).toList(),
          onChanged: enabled ? (v) => setState(() => _batchId = v) : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }
}
