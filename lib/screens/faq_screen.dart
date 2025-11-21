import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF693D2C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pertanyaan Umum (FAQ)',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        // Background image agar tampilan lebih elegan
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Overlay putih agar konten terbaca dengan jelas
          color: Colors.white.withOpacity(0.9),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Center(
                child: Text(
                  '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Apa itu Momnjo?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Momnjo adalah platform digital yang menyediakan layanan pijat bayi, spa bayi, pijat hamil, dan pregnancy massage, serta informasi terkait perawatan ibu dan bayi.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text(
                  'Bagaimana cara melakukan pemesanan layanan?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Anda dapat melakukan pemesanan layanan melalui aplikasi dengan memilih layanan yang diinginkan, mengisi data yang diperlukan, dan melakukan pembayaran melalui metode yang tersedia.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text(
                  'Bagaimana saya bisa mengetahui status pemesanan saya?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Status pemesanan dapat dilihat pada menu "Riwayat Transaksi" di aplikasi. Anda juga akan mendapatkan notifikasi melalui email atau SMS terkait status pemesanan Anda.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text(
                  'Bagaimana jika saya mengalami masalah saat menggunakan aplikasi?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Jika Anda mengalami masalah, silakan hubungi layanan pelanggan kami melalui menu "Contact Us & Suggestion" atau melalui email di [alamat email kami].',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text(
                  'Apakah ada promo atau diskon khusus untuk member?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ya, Momnjo menyediakan berbagai promo dan diskon khusus bagi member berdasarkan level keanggotaan seperti Bronze, Silver, Gold, Platinum Priority, dan Diamond Priority.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
