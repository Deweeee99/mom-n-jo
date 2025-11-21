import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _fullname = '';
  String _idCustomer = '';
  int _currentIndex = 4; // Tab Profile

  // Ganti ke endpoint delete account kamu jika path berbeda
  final String apiUrl = 'https://app.momnjo.com/api/delete_account.php';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Mengecek apakah user sudah login
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!loggedIn) {
      // Belum login, alihkan ke login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _isLoggedIn = true;
      });
      _loadUserData();
    }
  }

  /// Memuat data user dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullname = prefs.getString('fullname') ?? 'No Name';
      _idCustomer = prefs.getString('id_customer') ?? 'Unknown';
    });
  }

  /// Logout: hapus data dan navigasi ke login
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Navigasi ke screen lain (Bottom Navigation)
  void _navigateToScreen(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushNamed(context, '/gift');
        break;
      case 3:
        Navigator.pushNamed(context, '/voucher');
        break;
      case 4:
        // Tetap di halaman ini
        break;
    }
  }

  /// Fungsi untuk membuka URL eksternal
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Builder untuk item menu profil
  Widget _buildProfileItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  /// Fungsi untuk menghapus akun (soft delete)
  Future<void> _deleteAccount() async {
    // Konfirmasi user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Akun'),
        content: const Text(
            'Menghapus akun akan menghapus data pribadi Anda. Riwayat transaksi akan tetap tersimpan untuk kepentingan administrasi. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    // Optional: minta OTP atau verifikasi ulang di sini jika perlu
    // tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final idCustomer = prefs.getString('id_customer') ?? _idCustomer;

      // Jika endpoint memerlukan session cookie di server (PHP session),
      // perlu mekanisme cookie jar. Di sini kita kirim id_customer di body.
      final response = await http.post(Uri.parse(apiUrl), body: {
        'id_customer': idCustomer,
      }).timeout(const Duration(seconds: 30));

      Navigator.pop(context); // tutup loading

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success' || body['success'] == true) {
          // bersihkan prefs & redirect to login
          await prefs.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Akun berhasil dihapus')),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        } else {
          final msg =
              body['message'] ?? body['error'] ?? 'Gagal menghapus akun';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // pastikan loading tertutup
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // AppBar dengan warna putih agak transparan
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Background image di seluruh body
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            // Overlay putih transparan agar teks terbaca
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.85)),
            child: Column(
              children: [
                // Header Profil
                Container(
                  padding: const EdgeInsets.all(16),
                  // Gradasi halus agar lebih mewah
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD4B89C).withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          'https://placeholder.com/150x150',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fullname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF693D2C),
                        ),
                      ),
                      Text(
                        _idCustomer,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4B89C),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Member',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Riwayat Transaksi (placeholder)
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/memberstatus');
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 2,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF693D2C),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4B89C),
                          ),
                        ),
                        Text(
                          'Belanja dan kumpulkan poin untuk naik ke level selanjutnya!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daftar menu profil
                _buildProfileItem(
                  'Edit Profile',
                  onTap: () {
                    Navigator.pushNamed(context, '/editprofile');
                  },
                ),
                _buildProfileItem(
                  'Promo',
                  onTap: () {
                    _launchURL("https://www.momnjo.com/promo");
                  },
                ),
                _buildProfileItem(
                  'MPC Member Area',
                  onTap: () {
                    _launchURL("https://www.momnjo.com/mpc");
                  },
                ),
                _buildProfileItem(
                  'Contact Us & Suggestion',
                  onTap: () {
                    Navigator.pushNamed(context, '/ContactUsScreen');
                  },
                ),
                _buildProfileItem(
                  'Terms of Service',
                  onTap: () {
                    Navigator.pushNamed(context, '/TermsOfServiceScreen');
                  },
                ),
                _buildProfileItem(
                  'FAQ',
                  onTap: () {
                    Navigator.pushNamed(context, '/FAQScreen');
                  },
                ),

                // Tombol Hapus Akun (merah)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hapus Akun',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),

                // Tombol Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        color: Colors.white.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) => _navigateToScreen(context, index),
          selectedItemColor: const Color(0xFF693D2C),
          unselectedItemColor: Colors.grey,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text("Home"),
              selectedColor: const Color(0xFF693D2C),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              title: const Text("Booking"),
              selectedColor: const Color(0xFF693D2C),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.card_giftcard_outlined),
              title: const Text("Gift"),
              selectedColor: const Color(0xFF693D2C),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.confirmation_number_outlined),
              title: const Text("Voucher"),
              selectedColor: const Color(0xFF693D2C),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              selectedColor: const Color(0xFF693D2C),
            ),
          ],
        ),
      ),
    );
  }
}
