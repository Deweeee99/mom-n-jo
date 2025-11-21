import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

/// ===================
/// HELPERS & WIDGET LOADING
/// ===================

/// Fungsi untuk menampilkan loading animation sebelum navigasi.
void navigateWithLoading(
  BuildContext context,
  String routeName, {
  Object? arguments,
  bool replace = false,
  Duration delay = const Duration(milliseconds: 300),
}) {
  // Tampilkan dialog loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoadingDialog(),
  );

  // Setelah delay, hapus dialog dan lakukan navigasi.
  Future.delayed(delay, () {
    Navigator.pop(context); // Hapus loading dialog
    if (replace) {
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    } else {
      Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  });
}

/// Widget dialog yang menampilkan animasi loading hourglass.
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Menggunakan Center agar loading berada di tengah layar.
    return Center(
      child: HourglassLoading(),
    );
  }
}

/// Widget custom untuk menampilkan animasi loading hourglass.
class HourglassLoading extends StatefulWidget {
  const HourglassLoading({Key? key}) : super(key: key);

  @override
  _HourglassLoadingState createState() => _HourglassLoadingState();
}

class _HourglassLoadingState extends State<HourglassLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Animasi rotasi dari 0 hingga 180 derajat (0.0 - 0.5 putaran, karena 1.0 = 360°)
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 71, 60, 60),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: RotationTransition(
          turns: _animation,
          child: Container(
            width: 50,
            height: 70,
            // Gambar hourglass sederhana dengan CustomPaint
            child: CustomPaint(
              painter: HourglassPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar bentuk hourglass sederhana.
class HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    // Gambar bagian atas hourglass
    Path topPath = Path();
    topPath.moveTo(0, 0);
    topPath.quadraticBezierTo(size.width / 2, size.height * 0.5, size.width, 0);
    topPath.lineTo(size.width, size.height * 0.5);
    topPath.quadraticBezierTo(
        size.width / 2, size.height * 0.25, 0, size.height * 0.5);
    topPath.close();
    canvas.drawPath(topPath, paint);

    // Gambar bagian bawah hourglass
    Path bottomPath = Path();
    bottomPath.moveTo(0, size.height * 0.5);
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.75, size.width, size.height * 0.5);
    bottomPath.lineTo(size.width, size.height);
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.5, 0, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ===================
/// BOOKING SCREEN
/// ===================

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _idCustomer;
  bool _isLoggedIn = false;
  // Setelah menghapus item Booking dari bottom nav, index Gift = 1
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

  /// Navigasi bottom bar menggunakan loading animation.
  void _navigateToScreen(BuildContext context, int index) {
    if (index == _currentIndex) return;

    // Routes disesuaikan tanpa '/booking'
    final routes = [
      '/home',
      '/booking',
      '/gift',
      '/voucher',
      '/profile',
    ];

    if (index >= 0 && index < routes.length) {
      navigateWithLoading(context, routes[index]);
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
                    onPressed: () => navigateWithLoading(context, '/login'),
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
              // Tombol "Booking Sekarang" dihilangkan sesuai permintaan
              const SizedBox(height: 15),
              _buildActionButton(
                text: 'Lihat History',
                icon: Icons.history,
                onPressed: _navigateToHistory,
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
          // Booking item dihapus
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

  /// Navigasi ke history booking menggunakan loading animation.
  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history', arguments: _idCustomer);
  }
}
