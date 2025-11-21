// lib/screen/privacy_policy_screen.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang abu-abu terang
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Header Gradien dengan tombol kembali
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(243, 142, 218, 1),
                  Color.fromRGBO(255, 205, 243, 1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              top: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Judul di tengah
                  const Center(
                    child: Text(
                      'Kebijakan Privasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tombol kembali di kiri
                  Positioned(
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  '''
Kebijakan Privasi

Kami di Terapis Momnjo menghargai privasi Anda. Data yang kami kumpulkan (misalnya nama, kontak, riwayat medis) hanya digunakan untuk:
• Mengelola janji dan riwayat pasien.
• Komunikasi internal antara terapis dan pasien.
• Analisis statistik layanan.

Data tersebut **tidak** akan dibagikan ke pihak ketiga tanpa izin Anda. Kami menerapkan standar keamanan (enkripsi, akses terbatas) untuk melindungi informasi Anda. Jika ada pertanyaan lebih lanjut, silakan hubungi tim support kami.
''',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
