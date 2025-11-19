import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  bool _isLoggedIn = false;
  final int _currentIndex = 3;
  final Color _primaryColor = const Color(0xFF9B5D4C);
  final Color _accentColor = const Color(0xFFD4B89C);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (index == _currentIndex) return;

    final routes = [
      '/home',
      '/booking',
      '/gift',
      '/voucher',
      '/profile',
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  Widget _buildVoucherCard(
      String title, String validity, String terms, String discount) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berlaku hingga: $validity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Syarat & Ketentuan:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              terms,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Gunakan Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedUI() {
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/auth_required.png',
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.lock_person,
                    size: 150,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Akses Voucher',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Silakan login terlebih dahulu untuk melihat voucher yang tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Login Sekarang',
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
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAuthenticatedUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Saya'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemCount: 3, // Ganti dengan jumlah voucher sebenarnya
        itemBuilder: (context, index) {
          return _buildVoucherCard(
            'Paket Perawatan Premium',
            '31 Desember 2024',
            'Berlaku untuk semua cabang • Minimum transaksi Rp 500.000 • Tidak bisa digabung dengan promo lain',
            '20',
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => _navigateToScreen(context, index),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            title: const Text("Booking"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.card_giftcard_outlined),
            title: const Text("Gift"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.confirmation_number_outlined),
            title: const Text("Voucher"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text("Profile"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildAuthenticatedUI() : _buildUnauthenticatedUI();
  }
}
