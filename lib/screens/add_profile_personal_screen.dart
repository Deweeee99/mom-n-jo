import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddProfilePersonalScreen extends StatefulWidget {
  const AddProfilePersonalScreen({super.key});

  @override
  State<AddProfilePersonalScreen> createState() => _AddProfilePersonalScreenState();
}

class _AddProfilePersonalScreenState extends State<AddProfilePersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // ---> BRAY: Controller Alamat Dipecah Jadi Dua (Utama & Detail) <---
  final TextEditingController _mainAddressController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();

  // Status loading buat tombol lokasi
  bool _isLoadingLocation = false;

  // Tema Warna Sesuai Mockup
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Background
  final Color _btnDarkColor = const Color(0xFF4A2E20); // Coklat Gelap Tombol Continue
  final Color _accentColor = const Color(0xFFDBA38C); // Peach Terang buat aksen/icon
  final Color _mapBgColor = const Color(0xFFE2E8E8); // Warna abu-abu kebiruan buat map placeholder

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _emailController.dispose();
    _mainAddressController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  // Fungsi Ajaib Buat Narik Lokasi Otomatis (Geolocator)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service GPS HP lu mati Tuan, tolong nyalain dulu.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak nih.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin akses lokasi diblokir permanen dari setting HP.');
      }

      // Ambil Koordinat
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Translate Koordinat jadi Alamat Teks (Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Rangkai jadi satu kalimat alamat
          String fullAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea} ${place.postalCode}';
          
          // Bersihin kalau ada yang kosong (null)
          fullAddress = fullAddress.replaceAll(', ,', ',').replaceAll(',  ,', ',');
          
          setState(() {
            _mainAddressController.text = fullAddress; // Masuk ke kolom Cari Alamat
          });
        } else {
          setState(() {
            _mainAddressController.text = '${position.latitude}, ${position.longitude}';
          });
        }
      } catch (e) {
        setState(() {
          _mainAddressController.text = '${position.latitude}, ${position.longitude}';
        });
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      // Gabungin alamat utama dan detail
      String finalAddress = _mainAddressController.text;
      if (_detailAddressController.text.isNotEmpty) {
        finalAddress += '\nDetail: ${_detailAddressController.text}';
      }

      // Simpan data sementara, lalu lempar ke screen Emergency Contact
      final profileData = {
        'name': _nameController.text,
        'occupation': _occupationController.text,
        'email': _emailController.text,
        'address': finalAddress,
      };

      Navigator.pushNamed(
        context, 
        '/add_profile_emergency', 
        arguments: profileData,
      );
    }
  }

  // Label custom estetik mirip Mockup
  Widget _buildCustomLabel(String mainText, String subText, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: RichText(
        text: TextSpan(
          text: mainText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            fontFamily: 'serif', 
          ),
          children: [
            TextSpan(
              text: ' $subText',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                fontStyle: isRequired ? FontStyle.normal : FontStyle.italic,
                color: isRequired ? Colors.red.shade700 : _primaryColor,
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/images/logo_momnjo.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) => Text(
            'mom n jo',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Background Garis / Ornamen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_garis.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JUDUL HALAMAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          color: _primaryColor,
                        ),
                      ),
                      Icon(Icons.auto_awesome, color: _accentColor, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KOTAK FORM UTAMA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. FULL NAME
                          _buildCustomLabel('Full Name', '(required)', isRequired: true),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputStyle('e.g. Johanna Tan'),
                            validator: (value) => value!.isEmpty ? 'Nama lengkap wajib diisi' : null,
                          ),
                          const SizedBox(height: 20),

                          // 2. OCCUPATION
                          _buildCustomLabel('Occupation', '(optional)'),
                          TextFormField(
                            controller: _occupationController,
                            decoration: _inputStyle('e.g. Graphic Designer'),
                          ),
                          const SizedBox(height: 20),

                          // 3. EMAIL
                          _buildCustomLabel('Email', '(optional)'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputStyle('name@example.com'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---> BRAY: INI KOTAK ALAMAT BARU SESUAI MOCKUP TERAKHIR <---
                  _buildCustomLabel('Alamat Anda', '(required)', isRequired: true),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. Field Cari Alamat (Otomatis keisi sama GPS nanti)
                        TextFormField(
                          controller: _mainAddressController,
                          decoration: InputDecoration(
                            hintText: 'Cari Alamat',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Alamat utama wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),

                        // B. Placeholder Map (Peta Dummy)
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _mapBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFFF5A5F), size: 40),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Text(
                                  'Lokasi Anda',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // C. Tombol Ambil Lokasi (Coklat Full)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90604D), // Coklat sesuai gambar mockup
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: _isLoadingLocation
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.location_on, color: Colors.white, size: 18),
                            label: Text(
                              _isLoadingLocation ? 'Mencari Lokasi...' : 'Tandai Lokasi Saya Saat Ini',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // D. Field Detail Alamat (RT/RW, Patokan)
                        TextFormField(
                          controller: _detailAddressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Detail Alamat Manual (Unit, RT/RW, Patokan)',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // DUA TOMBOL DI BAWAH (BACK & CONTINUE)
                  Row(
                    children: [
                      // Tombol Back
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Tombol Continue
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _btnDarkColor, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.eco, color: Color(0xFF8B9A76), size: 18), // Daun
                              const SizedBox(width: 8),
                              const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.14159), // Balik arah daun
                                child: const Icon(Icons.eco, color: Color(0xFF8B9A76), size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper fungsi dekorasi Input form general
  InputDecoration _inputStyle(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }
}