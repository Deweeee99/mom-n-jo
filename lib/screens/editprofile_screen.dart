import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk semua field
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyNumberController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  String _selectedEmergencyStatus = 'Ayah';
  bool _isLoading = false;
  String _idCustomer = '';

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _emergencyStatusOptions = [
    'Ayah',
    'Istri',
    'Kerabat',
    'Orang tua',
    'Anak',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Memuat data awal dari SharedPreferences
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idCustomer = prefs.getString('id_customer') ?? '';
      _fullnameController.text = prefs.getString('fullname') ?? '';
      _nicknameController.text = prefs.getString('nickname') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _dobController.text = prefs.getString('date_of_birth') ?? '';
      _selectedGender = prefs.getString('gender') ?? 'Laki-laki';
      // Perbarui key untuk emergency: gunakan key baru
      _emergencyNameController.text = prefs.getString('emergency_nama') ?? '';
      _emergencyNumberController.text =
          prefs.getString('emergency_number') ?? '';
      _selectedEmergencyStatus = prefs.getString('emergency_status') ?? 'Ayah';
      // Untuk alamat, simpan dengan key 'alamat'
      _addressController.text = prefs.getString('address') ?? '';
    });
  }

  /// Mengirim data perubahan ke API
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Perbarui data yang dikirim menggunakan key yang sesuai
    final data = {
      'id_customer': _idCustomer,
      'fullname': _fullnameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'email': _emailController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'gender': _selectedGender,
      // Gunakan key baru: emergency_nama dan emergency_number
      'emergency_nama': _emergencyNameController.text.trim(),
      'emergency_number': _emergencyNumberController.text.trim(),
      'emergency_status': _selectedEmergencyStatus,
      // Gunakan key "address" saat dikirim (API akan simpan ke kolom "alamat")
      'address': _addressController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://app.momnjo.com/api/edit_profile.php'),
        body: data,
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _updateLocalPreferences();
        _showSuccessSnackbar(
            responseData['message'] ?? 'Profile updated successfully');
        Future.delayed(
            const Duration(seconds: 1), () => Navigator.pop(context));
      } else {
        _showErrorSnackbar(responseData['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showErrorSnackbar('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Memperbarui SharedPreferences dengan data terbaru
  Future<void> _updateLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullname', _fullnameController.text.trim());
    await prefs.setString('nickname', _nicknameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('date_of_birth', _dobController.text.trim());
    await prefs.setString('gender', _selectedGender);
    // Simpan dengan key baru
    await prefs.setString(
        'emergency_nama', _emergencyNameController.text.trim());
    await prefs.setString(
        'emergency_number', _emergencyNumberController.text.trim());
    await prefs.setString('emergency_status', _selectedEmergencyStatus);
    // Simpan alamat dengan key "alamat"
    await prefs.setString('address', _addressController.text.trim());
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Fungsi untuk memilih tanggal menggunakan DatePicker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData prefixIcon,
      {IconData? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6D4C41),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool readOnly = false,
      VoidCallback? onTap,
      String? Function(String?)? validator,
      int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: _inputDecoration(label, icon),
      validator: validator,
      maxLines: maxLines,
    );
  }

  /// Widget khusus untuk field Tanggal Lahir agar bisa diedit dan juga menggunakan date picker
  Widget _buildDateOfBirthField() {
    return TextFormField(
      controller: _dobController,
      decoration: InputDecoration(
        labelText: 'Tanggal Lahir',
        prefixIcon:
            Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _selectDate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Tanggal lahir wajib diisi' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFD4B89C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Informasi Pribadi'),
              _buildTextField(
                _fullnameController,
                'Nama Lengkap',
                Icons.person_outline,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _nicknameController,
                'Nickname',
                Icons.person,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Nickname wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _emailController,
                'Email',
                Icons.email_outlined,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Email wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildDateOfBirthField(),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration:
                    _inputDecoration('Jenis Kelamin', Icons.person_outline),
                items: _genderOptions
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
                validator: (val) => val == null ? 'Pilih jenis kelamin' : null,
              ),
              const SizedBox(height: 30),
              _buildSectionHeader('Kontak Darurat'),
              DropdownButtonFormField<String>(
                value: _selectedEmergencyStatus,
                decoration:
                    _inputDecoration('Status Hubungan', Icons.group_outlined),
                items: _emergencyStatusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedEmergencyStatus = value!),
              ),
              const SizedBox(height: 20),
              // Gunakan key baru untuk field kontak darurat
              _buildTextField(
                _emergencyNameController,
                'Nama Kontak Darurat',
                Icons.contact_emergency_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _emergencyNumberController,
                'Nomor Darurat',
                Icons.phone_android_outlined,
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Nomor darurat wajib diisi'
                    : null,
              ),
              const SizedBox(height: 30),
              _buildSectionHeader('Address'),
              // Untuk alamat, tampilkan dengan key "Alamat Lengkap"
              _buildTextField(
                _addressController,
                'Alamat Lengkap',
                Icons.home_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4B89C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
