import 'package:flutter/material.dart';

class MemberStatusScreen extends StatelessWidget {
  const MemberStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna utama MomNJo (sesuaikan jika perlu)
    const Color primaryColor = Color(0xFF693D2C);

    // Widget helper untuk menampilkan detail tiap level
    Widget buildMemberLevel({
      required String levelName,
      required List<String> benefits,
      Color? levelColor,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Buat sedikit gradasi pada box agar lebih elegan
          gradient: LinearGradient(
            colors: [
              Colors.white,
              (levelColor ?? primaryColor).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
            ),
          ],
          border: Border.all(
            color: levelColor ?? primaryColor.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              levelName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: levelColor ?? primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            for (var benefit in benefits)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• "),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    return Scaffold(
      // Jika ingin background sampai ke belakang AppBar, bisa pakai extendBodyBehindAppBar
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Member Status",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Container(
        // Pasang background image di Container utama
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            // Gunakan warna semi-transparan agar teks terlihat jelas di atas background
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Judul / Info singkat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Berikut detail setiap level member MomNJo. "
                    "Semakin tinggi level, semakin banyak bonus dan keuntungan yang kamu dapat!",
                    style: TextStyle(
                      fontSize: 14,
                      // Anda bisa menyesuaikan style agar lebih elegan
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bronze
                buildMemberLevel(
                  levelName: "Bronze Member",
                  benefits: [
                    "Points Member",
                    "Paket diskon 5%",
                  ],
                  levelColor: Colors.brown[400],
                ),

                // Silver
                buildMemberLevel(
                  levelName: "Silver Member",
                  benefits: [
                    "1.5x Points multiplier",
                    "Paket diskon 10%",
                  ],
                  levelColor: Colors.grey[600],
                ),

                // Gold
                buildMemberLevel(
                  levelName: "Gold Member",
                  benefits: [
                    "1.5x Points multiplier",
                    "Paket diskon 12%",
                    "Diskon produk 5%",
                  ],
                  levelColor: const Color(0xFFD4B89C),
                ),

                // Platinum Priority
                buildMemberLevel(
                  levelName: "Platinum Priority",
                  benefits: [
                    "2x Points multiplier",
                    "Paket diskon 15%",
                    "Diskon produk 10%",
                  ],
                  levelColor: const Color(0xFF693D2C),
                ),

                // Diamond Priority
                buildMemberLevel(
                  levelName: "Diamond Priority",
                  benefits: [
                    "2x Points multiplier",
                    "Paket diskon 15%",
                    "Diskon produk 12%",
                    "Priority Customer Service",
                    "Cashback",
                  ],
                  levelColor: Colors.blueGrey[800],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
