import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

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
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  String _selectedEmergencyStatus = 'Ayah';
  bool _isLoading = false;
  bool _isLoadingLocation = false; // Status loading saat mencari lokasi GPS
  String _idCustomer = '';

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _emergencyStatusOptions = [
    'Ayah',
    'Istri',
    'Suami',
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
      _emergencyNameController.text = prefs.getString('emergency_nama') ?? '';
      _emergencyNumberController.text = prefs.getString('emergency_number') ?? '';
      _selectedEmergencyStatus = prefs.getString('emergency_status') ?? 'Ayah';
      _addressController.text = prefs.getString('address') ?? '';
    });
  }

  /// Mengirim data perubahan ke API
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'id_customer': _idCustomer,
      'fullname': _fullnameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'email': _emailController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'gender': _selectedGender,
      'emergency_nama': _emergencyNameController.text.trim(),
      'emergency_number': _emergencyNumberController.text.trim(),
      'emergency_status': _selectedEmergencyStatus,
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
        _showSuccessSnackbar(responseData['message'] ?? 'Profile updated successfully');
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
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
    await prefs.setString('emergency_nama', _emergencyNameController.text.trim());
    await prefs.setString('emergency_number', _emergencyNumberController.text.trim());
    await prefs.setString('emergency_status', _selectedEmergencyStatus);
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

  /// Fungsi untuk mendapatkan lokasi GPS dan menerjemahkan ke teks alamat
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Cek apakah layanan GPS menyala
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackbar('Layanan lokasi (GPS) tidak aktif. Mohon nyalakan GPS.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 2. Cek apakah aplikasi sudah diberi izin mengakses GPS
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackbar('Izin akses lokasi ditolak oleh pengguna.');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackbar('Izin lokasi ditolak permanen. Silakan ubah secara manual di Pengaturan HP Anda.');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // 3. Ambil titik koordinat saat ini
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 4. Ubah koordinat menjadi teks alamat (Geocoding)
      // DIBUNGKUS TRY-CATCH KHUSUS BIAR AMAN DI WINDOWS DESKTOP!
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          
          // Gabungkan elemen alamat dengan aman
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
          if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
          if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) addressParts.add(place.subAdministrativeArea!);
          if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);

          String address = addressParts.join(', ');
          
          setState(() {
            _addressController.text = address; // Isi kolom otomatis
          });
          _showSuccessSnackbar('Lokasi berhasil ditemukan!');
        }
      } catch (e) {
        // JARING PENGAMAN: Kalo geocoding gagal (karena dijalanin di Windows)
        // Set nilai Latitude dan Longitude aja biar gak layar merah
        setState(() {
          _addressController.text = 'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
        });
        _showSuccessSnackbar('Koordinat berhasil didapat (Geocoding tidak didukung di Windows)');
      }

    } catch (e) {
      _showErrorSnackbar('Gagal mendapatkan lokasi: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  /// Fungsi untuk memilih tanggal
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateTime.tryParse(_dobController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF693D2C), // Warna MomNJo
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  // --- WIDGET HELPER UI SESUAI MOCKUP ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5A3D31), // Cokelat gelap
        ),
      ),
    );
  }

  /// Membangun kotak input (card) sesuai dengan Mockup
  Widget _buildCardField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[500], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                // Child ini adalah textfield atau dropdown tanpa border bawaan
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Konfigurasi input form tanpa garis bawah
  InputDecoration _cleanInputDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.only(top: 4, bottom: 2),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EBE6), // Background peach pucat full layar
      body: Column(
        children: [
          // --- HEADER COKELAT MELENGKUNG ---
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF5E392A), // Warna coklat gelap persis desain
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar Custom
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Text(
                      'Edit Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white, size: 24),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 30),
                // Profil Detail
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Lingkaran pudar luar
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFDCC7B5), // Warna dalam avatar
                        child: Icon(Icons.person, color: Colors.white, size: 45),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullnameController.text.isNotEmpty ? _fullnameController.text : 'Dewa TSI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Healthy pregnancy, baby',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),

          // --- FORM CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Nama Lengkap & Nickname
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            label: 'Nama Lengkap',
                            icon: Icons.person_outline,
                            child: TextFormField(
                              controller: _fullnameController,
                              decoration: _cleanInputDecoration(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCardField(
                            label: 'Nickname',
                            icon: Icons.person,
                            child: TextFormField(
                              controller: _nicknameController,
                              decoration: _cleanInputDecoration(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ROW 2: Email
                    _buildCardField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _cleanInputDecoration(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ROW 3: Tanggal Lahir & Jenis Kelamin
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            label: 'Tanggal Lahir',
                            icon: Icons.calendar_today_outlined,
                            child: InkWell(
                              onTap: _selectDate,
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: _dobController,
                                  decoration: _cleanInputDecoration(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCardField(
                            label: 'Jenis Kelamin',
                            icon: Icons.person_outline,
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: _cleanInputDecoration(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                              items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                              onChanged: (value) => setState(() => _selectedGender = value!),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- KONTAK DARURAT ---
                    _buildSectionHeader('Kontak Darurat'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCardField(
                            label: 'Status Hubungan',
                            icon: Icons.group_outlined,
                            child: DropdownButtonFormField<String>(
                              value: _selectedEmergencyStatus,
                              decoration: _cleanInputDecoration(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                              items: _emergencyStatusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                              onChanged: (value) => setState(() => _selectedEmergencyStatus = value!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCardField(
                            label: 'Nama',
                            icon: Icons.badge_outlined,
                            child: TextFormField(
                              controller: _emergencyNameController,
                              decoration: _cleanInputDecoration(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCardField(
                      label: 'Nomor Darurat',
                      icon: Icons.phone_android_outlined,
                      child: TextFormField(
                        controller: _emergencyNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: _cleanInputDecoration(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),

                    // --- ALAMAT ANDA (Desain Spesifik) ---
                    _buildSectionHeader('Alamat Anda'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Field Cari Alamat
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      hintText: 'Cari Alamat',
                                      hintStyle: TextStyle(fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // --- KOTAK MAP BIRU MUDA SESUAI DESAIN ---
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE5E7), // Warna biru muda polos sesuai desain
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pin Lokasi & Teks
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFFFF5252), size: 45), // Merah terang
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20), // Pill shape
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                                        ],
                                      ),
                                      child: const Text(
                                        'Lokasi Anda',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ------------------------

                          const SizedBox(height: 16),
                          // Tombol Tandai Lokasi
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.location_on, color: Colors.white, size: 18),
                              label: Text(
                                _isLoadingLocation ? 'Mencari Lokasi...' : 'Tandai Lokasi Saya Saat Ini', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF966A55), // Coklat medium pas dengan desain
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Field Detail Alamat Manual
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Detail Alamat Manual (Unit, RT/RW, Patokan)',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E392A), // Coklat gelap senada header
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'SIMPAN PERUBAHAN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}