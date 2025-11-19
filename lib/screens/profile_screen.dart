import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

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

  /// Builder untuk item menu profil
  Widget _buildProfileItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEEEEEE),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.black),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profil
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        NetworkImage('https://placeholder.com/150x150'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fullname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _idCustomer,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4B89C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Member Gold',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Riwayat Transaksi
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Rp 0',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4B89C),
                    ),
                  ),
                  Text(
                    'Belanja dan kumpulkan poin untuk naik ke level selanjutnya!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Daftar menu profil
            _buildProfileItem(
              'Edit Profile',
              onTap: () {
                Navigator.pushNamed(context, '/editprofile');
              },
            ),
            _buildProfileItem('Referral Code', onTap: () {
              // Implementasi navigasi atau aksi untuk Referral Code
            }),
            _buildProfileItem('Credit Card', onTap: () {
              // Implementasi navigasi atau aksi untuk Credit Card
            }),
            _buildProfileItem('Contact Us & Suggestion', onTap: () {
              // Implementasi navigasi atau aksi untuk Contact Us & Suggestion
            }),
            _buildProfileItem('Rate', onTap: () {
              // Implementasi navigasi atau aksi untuk Rate
            }),
            _buildProfileItem('Terms of Service', onTap: () {
              // Implementasi navigasi atau aksi untuk Terms of Service
            }),
            _buildProfileItem('FAQ', onTap: () {
              // Implementasi navigasi atau aksi untuk FAQ
            }),

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
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) => _navigateToScreen(context, index),
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
