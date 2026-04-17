import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Animasi fade-in (muncul pelan-pelan)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Panggil fungsi buat nunggu 5 detik terus ngecek login
    _navigateNext();
  }

  // ---> BRAY: Ini fungsi logika barunya <---
  Future<void> _navigateNext() async {
    // Tunggu 5 detik sesuai durasi splash screen lu sebelumnya
    await Future.delayed(const Duration(seconds: 5));
    
    if (!mounted) return;

    // Cek status login di memori lokal
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      // Kalo udah login, lempar ke halaman pilih profil!
      Navigator.pushReplacementNamed(context, '/profile_selection');
    } else {
      // Kalo belom login, biarin aja masuk ke Home sebagai Guest
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Pastikan nama filenya bg_landing.png sesuai yang Tuan punya
                image: AssetImage('assets/images/bg_landing.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Konten Animasi
          AnimatedOpacity(
            duration: const Duration(seconds: 1), // Durasi munculnya
            opacity: _opacity,
            // Dibungkus SingleChildScrollView biar ga error Overflowed kalo layarnya kecil
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // WELCOME TEXT
                    const Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'serif', // Pake font serif biar mirip desain asli
                        letterSpacing: 2.0,
                        color: Color(0xFF693D2C), // Warna coklat tua khas Mom n Jo
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // LOGO
                    Image.asset(
                      'assets/images/logo_momnjo.png',
                      width: 220,
                    ),

                    const SizedBox(height: 40),

                    // ICON ANAK PEREMPUAN
                    Transform.translate(
                      offset: const Offset(-30, 0), // Geser dikit ke kiri
                      child: Transform.rotate(
                        angle: -0.1, // Miringin dikit biar playful
                        child: Image.asset(
                          // Kalau file Tuan .jpg, ganti jadi .jpg ya!
                          'assets/images/icon_perempuan.png', 
                          width: 150,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 150,
                            child: Center(child: Text('Aset perempuan belum ada')),
                          ),
                        ),
                      ),
                    ),

                    // ICON ANAK LAKI-LAKI
                    Transform.translate(
                      offset: const Offset(40, -30), // Geser dikit ke kanan dan naik
                      child: Transform.rotate(
                        angle: 0.1, // Miringin ke kanan
                        child: Image.asset(
                          // Kalau file Tuan .jpg, ganti jadi .jpg ya!
                          'assets/images/icon_laki.png', 
                          width: 140,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 140,
                            child: Center(child: Text('Aset laki-laki belum ada')),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50), // Ganti Spacer jadi SizedBox biar aman di ScrollView

                    // ORNAMEN DAUN DI BAWAH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.energy_savings_leaf_outlined,
                          color: Color(0xFF8B9A76), // Warna hijau daun
                          size: 35,
                        ),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(3.14159), // Balik arah daunnya
                          child: const Icon(
                            Icons.energy_savings_leaf_outlined,
                            color: Color(0xFF907C64), // Warna kecoklatan
                            size: 35,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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