import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model Sementara (Dummy) sebelum ada API dari Backend
class FamilyProfile {
  final String id;
  final String title; // Contoh: "MOM (YOU)", "BABY (JO)"
  final String name;
  final String subtitle; // Contoh: "(Dewa TSI)", "(Age 11 months)"
  final String description; // Contoh: "For Mom-to-be / Postpartum"
  final String imagePath; // Path gambar avatar
  final bool isAddNew;

  FamilyProfile({
    required this.id,
    required this.title,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    this.isAddNew = false,
  });
}

class ProfileSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;

  const ProfileSelectionScreen({super.key, this.bookingData});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  String _fullname = "Loading...";
  
  // Tema Warna Sesuai Mockup
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Background

  // Data Dummy Mockup (Nanti diganti nembak API get_family_profiles.php)
  final List<FamilyProfile> _profiles = [
    FamilyProfile(
      id: '1',
      title: 'MOM (YOU)',
      name: 'Ristian',
      subtitle: '(Dewa TSI)',
      description: 'For Mom-to-be / Postpartum',
      imagePath: 'assets/images/icon_perempuan.png', // Ganti aset avatar ibu
    ),
    FamilyProfile(
      id: '2',
      title: 'BABY (JO)',
      name: 'Johanna',
      subtitle: '(Age 11 months)',
      description: 'For Baby Spa / Massage',
      imagePath: 'assets/images/icon_perempuan.png', // Ganti aset avatar bayi
    ),
    FamilyProfile(
      id: '3',
      title: 'CHILD (MOMI)',
      name: 'Momi',
      subtitle: '(Age 4 years)',
      description: 'For Kids\' Spa / Fun Baths',
      imagePath: 'assets/images/icon_perempuan.png', // Ganti aset avatar anak
    ),
    // Item khusus buat tombol Add New Profile
    FamilyProfile(
      id: 'add',
      title: '',
      name: '',
      subtitle: '',
      description: '',
      imagePath: '',
      isAddNew: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullname = prefs.getString('fullname') ?? 'Dewa TSI';
    });
  }

  // Fungsi navigasi pas user nge-klik salah satu card profil
  void _selectProfileAndNavigate(FamilyProfile selectedProfile) async {
    // Simpan profil yang dipilih ke memori lokal buat dipake di Home / Booking nanti
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_profile_id', selectedProfile.id);
    await prefs.setString('active_profile_name', selectedProfile.name);
    await prefs.setString('active_profile_title', selectedProfile.title);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil masuk sebagai: ${selectedProfile.name}'),
        duration: const Duration(seconds: 1),
      ),
    );

    // Langsung lempar ke Home dan hapus tumpukan layar sebelumnya (seperti Login)
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // AppBar dibikin transparan biar nyatu sama background
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
        actions: [
          const Icon(Icons.auto_awesome, color: Color(0xFFDBA38C), size: 24),
          const SizedBox(width: 16),
        ],
      ),

      // ---> BRAY: Bottom Navigation Bar udah diilangin total! <---

      body: Stack(
        children: [
          // Background Lines
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER TEXT
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $_fullname!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFDBA38C), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Select a profile to book for:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              fontStyle: FontStyle.italic,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // GRID PROFIL CARDS
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.68, // Ngatur proporsi tinggi vs lebar card
                    ),
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];

                      // KALO INI KARTU "ADD NEW PROFILE"
                      if (profile.isAddNew) {
                        return GestureDetector(
                          onTap: () {
                            // ---> BRAY: Typonya udah gua benerin ya jadi '/add_profile_personal' <---
                            Navigator.pushNamed(context, '/add_profile_personal');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Buka halaman tambah profil baru')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD4B89C), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, color: Color(0xFFDBA38C), size: 20),
                                const SizedBox(height: 12),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _primaryColor, width: 2),
                                  ),
                                  child: Icon(Icons.add, color: _primaryColor, size: 36),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ADD NEW\nPROFILE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // KALO INI KARTU PROFIL BIASA (DIBIKIN LANGSUNG NAVIGASI PAS DIKLIK)
                      return GestureDetector(
                        onTap: () => _selectProfileAndNavigate(profile),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Title (MOM, BABY, dll)
                                Text(
                                  profile.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: _primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Foto Avatar
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                                    ],
                                    image: const DecorationImage(
                                      image: AssetImage('assets/darmawangsa.png'), // GANTI ASET LU BRAY
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Nama
                                Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                // Subtitle
                                Text(
                                  profile.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Spacer(),
                                
                                // Deskripsi Bawah
                                Text(
                                  profile.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}