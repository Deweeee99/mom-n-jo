import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DaftarScreen extends StatefulWidget {
  const DaftarScreen({Key? key}) : super(key: key);

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  bool _isLoading = false;

  // Variabel untuk list gerai dan nilai yang dipilih
  List<dynamic> _geraiList = [];
  String? _selectedGeraiId; // menyimpan id_gerai yang dipilih

  @override
  void initState() {
    super.initState();
    _fetchGerai();
  }

  // Fungsi mengambil data gerai secara dinamis dari API
  Future<void> _fetchGerai() async {
    try {
      final response = await http
          .get(Uri.parse('https://app.momnjo.com/api/list_gerai.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _geraiList =
              data; // asumsikan API mengembalikan list array data gerai
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching gerai: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching gerai: $e')),
      );
    }
  }

  Future<void> _register() async {
    // Validasi field wajib
    if (_fullnameController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _dateOfBirthController.text.isEmpty ||
        _selectedGeraiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang wajib')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://app.momnjo.com/api/daftar.php'),
        body: {
          'fullname': _fullnameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'mobile_no': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
          'date_of_birth': _dateOfBirthController.text.trim(),
          'id_gerai': _selectedGeraiId!,
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          // Navigasi atau tindakan lain setelah pendaftaran berhasil
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ??
                  'Pendaftaran gagal, silakan coba lagi'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _nicknameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5E6E0), Color(0xFFFEF9F5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Color(0xFFD4B89C),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Registration Form Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Fullname Field
                        TextFormField(
                          controller: _fullnameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Nama Lengkap',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nickname Field
                        TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Nama Panggilan',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Mobile Number Field
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone_android,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Nomor Handphone',
                            hintText: '+628888888',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Email',
                            hintText: 'Password akan dikirim melalui Email',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Date of Birth Field
                        TextFormField(
                          controller: _dateOfBirthController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.cake,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Tanggal Lahir',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'YYYY-MM-DD',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Gerai Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedGeraiId,
                          items:
                              _geraiList.map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item['id_gerai'].toString(),
                              child: Text(item['nama_gerai']),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.store,
                                color: Color(0xFFD4B89C)),
                            labelText: 'Pilih Gerai',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedGeraiId = value;
                            });
                          },
                          hint: const Text('Pilih Gerai'),
                        ),
                        const SizedBox(height: 24),
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4B89C),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'DAFTAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Link kembali ke halaman Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFFD4B89C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
