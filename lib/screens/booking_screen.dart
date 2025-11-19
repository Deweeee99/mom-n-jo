import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _idCustomer;
  bool _isLoggedIn = false;
  final int _currentIndex = 1;
  final Color _primaryColor = const Color(0xFF9B5D4C);
  final Color _accentColor = const Color(0xFFD4B89C);

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _idCustomer = prefs.getString('id_customer');
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

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildAuthenticatedUI() : _buildUnauthenticatedUI();
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
                  'Akses Booking',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Silakan login terlebih dahulu untuk melakukan booking',
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
      bottomNavigationBar: _buildBottomNavBar(),
      body: Stack(
        children: [
          _buildBackground(),
          _buildBookingCard(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _primaryColor.withOpacity(0.2),
            Colors.white.withOpacity(0.8)
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/bookbg.png'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 60, color: Colors.black54),
              const SizedBox(height: 20),
              Text(
                'Mulai Booking Anda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Dapatkan diskon Rp75.000 untuk booking pertama dengan mereferensikan aplikasi ini ke teman Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildActionButton(
                text: 'Booking Sekarang',
                icon: Icons.add_circle_outline,
                onPressed: () => _navigateToBookingForm(),
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                text: 'Lihat History',
                icon: Icons.history,
                onPressed: () => _navigateToHistory(),
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Function() onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: isPrimary ? Colors.white : _primaryColor),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isPrimary ? Colors.white : _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? _primaryColor : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isPrimary ? BorderSide.none : BorderSide(color: _primaryColor),
          ),
          elevation: isPrimary ? 3 : 0,
        ),
      ),
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

  void _navigateToBookingForm() {
    Navigator.pushNamed(
      context,
      '/Tambah',
      arguments: _idCustomer,
    );
  }

  void _navigateToHistory() {
    Navigator.pushNamed(
      context,
      '/History',
      arguments: _idCustomer,
    );
  }
}
