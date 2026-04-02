import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/utils/date_utils.dart';

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
    
    _dateOfJoining = DateTime.tryParse(_userData['date_of_joining'] ?? '') ?? GymDateUtils.getNowIST();
    _membershipExpiry = DateTime.tryParse(_userData['membership_expiry'] ?? '') ?? GymDateUtils.getNowIST();
    
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
        }
      }
    } catch (_) {}
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
        title: const Text('RESET PASSWORD?'),
        content: const Text('Password will be reset to "samgym". Member must change it on next login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('RESET', style: TextStyle(color: Colors.white)),
          ),
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
    final name = _userData['name'] ?? 'Member';
    final phone = _userData['phone'];
    if (phone == null) return;

    String message = "Hi $name, staying consistent is key! Ready for today's workout?";
    if (_bodyType == 'skinny') {
      message = "Hey $name, looking to bulk up? Check out our high-protein diet charts at the reception!";
    } else if (_bodyType == 'fatty') {
      message = "Hey $name, focus on cardio and high reps today for maximum fat burn!";
    }

    final url = "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchCall() async {
    final phone = _userData['phone'];
    if (phone == null) return;
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT MEMBER' : 'MEMBER PROFILE'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true), 
              icon: Icon(Icons.edit_outlined, color: AppColors.text3(context), size: 22),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveChanges, 
              child: const Text('SAVE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 32),

              if (!_isEditing) ...[
                Row(
                  children: [
                    Expanded(child: _buildActionBtn(Icons.phone, 'CALL', Colors.blue, _launchCall)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionBtn(Icons.chat_bubble_outline, 'WHATSAPP', AppColors.success, _launchWhatsApp)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionBtn(Icons.lock_reset, 'RESET ACCOUNT PASSWORD', AppColors.primary, _resetPassword, isFullWidth: true),
                const SizedBox(height: 32),
              ],

              _buildSectionLabel('PERSONAL DETAILS'),
              const SizedBox(height: 12),
              _buildField('FULL NAME', _nameController, Icons.person_outline, enabled: _isEditing),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('PHONE', _phoneController, Icons.phone_android_outlined, enabled: _isEditing, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('ALT PHONE', _phoneAltController, Icons.contact_phone_outlined, enabled: _isEditing, keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('FATHER / GUARDIAN', _fatherNameController, Icons.family_restroom_outlined, enabled: _isEditing),
              
              const SizedBox(height: 32),
              _buildSectionLabel('MEMBERSHIP & BATCH'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDatePicker('JOINING DATE', _dateOfJoining, _isEditing ? () => _selectDate(context, true) : null)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('EXPIRY DATE', _membershipExpiry, _isEditing ? () => _selectDate(context, false) : null)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildBatchDropdown()),
                   const SizedBox(width: 16),
                   Expanded(child: _buildDropdown('FEES STATUS', _feesStatus, ['paid', 'pending'], _isEditing ? (v) => setState(() => _feesStatus = v!) : null)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildDropdown('PLAN', _membershipPlan, ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual'], _isEditing ? (v) => setState(() => _membershipPlan = v!) : null)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildDropdown('BODY TYPE', _bodyType, ['skinny', 'normal', 'fatty'], _isEditing ? (v) => setState(() => _bodyType = v!) : null)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionLabel('OTHER INFORMATION'),
              const SizedBox(height: 12),
              _buildField('ROLL NO', _rollNoController, Icons.numbers_outlined, enabled: _isEditing),
              const SizedBox(height: 16),
              _buildField('ADDRESS', _addressController, Icons.home_outlined, enabled: _isEditing, maxLines: 2),
              const SizedBox(height: 16),
              _buildField('INTERNAL NOTES', _notesController, Icons.note_add_outlined, enabled: _isEditing, maxLines: 3),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGlow.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_userData['name'] ?? 'MEMBER').toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: #${_userData['id'].toString().substring(0, 8).toUpperCase()}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: TextStyle(color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap, {bool isFullWidth = false}) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Icon(Icons.calendar_today, size: 16, color: enabled ? AppColors.primary : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?>? onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      dropdownColor: AppColors.surf(context),
      iconEnabledColor: AppColors.primary,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(color: AppColors.text1(context), fontSize: 13, fontWeight: FontWeight.w600),
      items: items.map((p) => DropdownMenuItem(
        value: p, 
        child: Text(p.toUpperCase(), style: TextStyle(color: AppColors.text1(context)))
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String>(
      value: _batches.any((b) => b['id'] == _batchId) ? _batchId : null,
      dropdownColor: AppColors.surf(context),
      iconEnabledColor: AppColors.primary,
      decoration: const InputDecoration(labelText: 'ASSIGNED BATCH'),
      style: TextStyle(color: AppColors.text1(context), fontSize: 13, fontWeight: FontWeight.w600),
      hint: Text('Select Batch', style: TextStyle(color: AppColors.text3(context))),
      items: _batches.map((b) => DropdownMenuItem(
        value: b['id'] as String, 
        child: Text((b['name'] ?? '???').toUpperCase(), style: TextStyle(color: AppColors.text1(context)))
      )).toList(),
      onChanged: _isEditing ? (v) => setState(() => _batchId = v) : null,
    );
  }
}
