import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/user_service.dart';
import '../../widgets/profile/personal_info_section.dart';
import '../../widgets/profile/health_info_section.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userFormKey = GlobalKey<FormState>();
  final _healthFormKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = '';
  final _addressCtrl = TextEditingController();
  final _emgNameCtrl = TextEditingController();
  final _emgPhoneCtrl = TextEditingController();

  final _heightCtrl = TextEditingController();
  String _bloodType = '';
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _currentMedsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = false;
  bool _userSaveSuccess = false;
  bool _healthSaveSuccess = false;
  String? _error;
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService(ApiClient());
    _loadData();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _emgNameCtrl.dispose();
    _emgPhoneCtrl.dispose();
    _heightCtrl.dispose();
    _chronicCtrl.dispose();
    _allergiesCtrl.dispose();
    _currentMedsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _userService.getCurrentUser();
      _fullNameCtrl.text = user['full_name'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
      _phoneCtrl.text = user['phone'] ?? '';
      _dobCtrl.text = user['date_of_birth'] ?? '';
      _gender = (user['gender'] ?? '') as String;
      _addressCtrl.text = user['address'] ?? '';
      _emgNameCtrl.text = user['emergency_contact_name'] ?? '';
      _emgPhoneCtrl.text = user['emergency_contact_phone'] ?? '';

      // Try to load health profile, but it's okay if it doesn't exist yet
      final hp = await _userService.getHealthProfileOrNull();
      if (hp != null) {
        _heightCtrl.text = (hp['height']?.toString() ?? '');
        _bloodType = (hp['blood_type'] ?? '') as String;
        _chronicCtrl.text = (hp['chronic_diseases'] as List?)?.join(', ') ?? '';
        _allergiesCtrl.text = (hp['allergies'] as List?)?.join(', ') ?? '';
        _currentMedsCtrl.text = (hp['current_medications'] as List?)?.join(', ') ?? '';
        _notesCtrl.text = hp['medical_notes'] ?? '';
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thông tin. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_userFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _userSaveSuccess = false;
    });
    try {
      await _userService.updateUser({
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        'gender': _gender.isEmpty ? null : _gender,
        'address': _addressCtrl.text.trim(),
        'emergency_contact_name': _emgNameCtrl.text.trim(),
        'emergency_contact_phone': _emgPhoneCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _userSaveSuccess = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cập nhật thông tin cá nhân thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _userSaveSuccess = false;
          });
        }
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể cập nhật thông tin. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveHealth() async {
    if (!_healthFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _healthSaveSuccess = false;
    });
    try {
      final body = {
        'height': _heightCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_heightCtrl.text.trim()),
        'blood_type': _bloodType.isEmpty ? null : _bloodType,
        'chronic_diseases': _chronicCtrl.text.trim().isEmpty
            ? []
            : _chronicCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'allergies': _allergiesCtrl.text.trim().isEmpty
            ? []
            : _allergiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'current_medications': _currentMedsCtrl.text.trim().isEmpty
            ? []
            : _currentMedsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'medical_notes': _notesCtrl.text.trim(),
      };
      try {
        await _userService.updateHealthProfile(body);
      } catch (_) {
        await _userService.createHealthProfile(body);
      }
      if (!mounted) return;
      setState(() {
        _healthSaveSuccess = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cập nhật hồ sơ sức khỏe thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _healthSaveSuccess = false;
          });
        }
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể cập nhật hồ sơ sức khỏe. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading && _fullNameCtrl.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[800], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[800], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Personal info
                  PersonalInfoSection(
                    formKey: _userFormKey,
                    fullNameCtrl: _fullNameCtrl,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    dobCtrl: _dobCtrl,
                    gender: _gender,
                    addressCtrl: _addressCtrl,
                    emgNameCtrl: _emgNameCtrl,
                    emgPhoneCtrl: _emgPhoneCtrl,
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onDateTap: _selectDate,
                    showSuccess: _userSaveSuccess,
                    isLoading: _loading,
                    onSave: _saveUser,
                  ),

                  const SizedBox(height: 16),

                  // Health profile
                  HealthInfoSection(
                    formKey: _healthFormKey,
                    heightCtrl: _heightCtrl,
                    bloodType: _bloodType,
                    chronicCtrl: _chronicCtrl,
                    allergiesCtrl: _allergiesCtrl,
                    currentMedsCtrl: _currentMedsCtrl,
                    notesCtrl: _notesCtrl,
                    onBloodTypeChanged: (v) => setState(() => _bloodType = v),
                    showSuccess: _healthSaveSuccess,
                    isLoading: _loading,
                    onSave: _saveHealth,
                  ),
                ],
              ),
            ),
    );
  }
}
