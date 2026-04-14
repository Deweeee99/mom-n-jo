import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoadingDialog(),
  );

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
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: HourglassLoading(),
    );
  }
}

/// Widget custom untuk menampilkan animasi loading hourglass.
class HourglassLoading extends StatefulWidget {
  const HourglassLoading({super.key});

  @override
  State<HourglassLoading> createState() => _HourglassLoadingState();
}

class _HourglassLoadingState extends State<HourglassLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
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
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 71, 60, 60),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: RotationTransition(
          turns: _animation,
          child: SizedBox(
            width: 50,
            height: 70,
            child: CustomPaint(
              painter: HourglassPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    Path topPath = Path();
    topPath.moveTo(0, 0);
    topPath.quadraticBezierTo(size.width / 2, size.height * 0.5, size.width, 0);
    topPath.lineTo(size.width, size.height * 0.5);
    topPath.quadraticBezierTo(
        size.width / 2, size.height * 0.25, 0, size.height * 0.5);
    topPath.close();
    canvas.drawPath(topPath, paint);

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
  
  // Update warna menyesuaikan tema baru Tuan
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat tua khas Momnjo
  final Color _accentColor = const Color(0xFFDEBC9E); // Peach gradient

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

  @override
  Widget build(BuildContext context) {
    // Karena dipanggil di dalam Home (Shell), kita nggak pake bottomNavigationBar lagi di sini.
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4), // Tema peach muda
      body: _isLoggedIn ? _buildAuthenticatedUI() : _buildUnauthenticatedUI(),
    );
  }

  /// TAMPILAN JIKA BELUM LOGIN
  Widget _buildUnauthenticatedUI() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Lock Estetik
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9EAE1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 50,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Akses Booking',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan login terlebih dahulu untuk melakukan booking treatment favorit Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Tombol Login
              InkWell(
                onTap: () => navigateWithLoading(context, '/login'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDEBC9E), Color(0xFFC8A386)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8A386).withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Login Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
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

  /// TAMPILAN JIKA SUDAH LOGIN
  Widget _buildAuthenticatedUI() {
    return Stack(
      children: [
        _buildBackground(),
        Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Clipboard / History Estetik
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9EAE1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_edu_rounded,
                      size: 45,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Booking History',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _primaryColor,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lihat riwayat booking Anda atau mulai buat pesanan treatment baru sekarang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Tombol Primary (Booking Sekarang)
                  InkWell(
                    // Sementara arahin ke halaman kategori (Home) biar milih treatment dulu,
                    // Nanti disesuaikan udah bikin alur input booking-nya
                    onTap: () => navigateWithLoading(context, '/kategori'), 
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B5D4C), // Coklat bata yang premium
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9B5D4C).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Booking Sekarang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tombol Outline (Lihat History)
                  _buildOutlineActionButton(
                    text: 'Lihat History',
                    icon: Icons.history,
                    onPressed: _navigateToHistory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F4), // Solid background menyesuaikan tema
        image: DecorationImage(
          image: AssetImage('assets/bookbg.png'),
          fit: BoxFit.cover,
          opacity: 0.15, // Dibuat lebih tipis biar nggak nabrak text
        ),
      ),
    );
  }

  Widget _buildOutlineActionButton({
    required String text,
    required IconData icon,
    required Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: _primaryColor, size: 20),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: _primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history', arguments: _idCustomer);
  }
}