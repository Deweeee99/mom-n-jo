import 'package:flutter/material.dart';

class MemberStatusScreen extends StatelessWidget {
  const MemberStatusScreen({super.key});

  // Widget helper dipindah ke luar build() agar lebih rapi
  Widget _buildTierCard({
    required String title,
    required List<String> benefits,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5), // Sesuai mockup, menggunakan border
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, color: Color(0xFF333333))),
                Expanded(
                  child: Text(
                    b,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Background solid bersih sesuai mockup
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0, // Dihilangkan agar rata dengan background
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Member Status',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Info Box Banner (Paling atas)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE6DF), // Warna box info abu kecoklatan muda
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Berikut detail setiap level member MomNJo.\nSemakin tinggi level, semakin banyak bonus dan keuntungan yang kamu dapat!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A4A4A),
                  height: 1.5,
                ),
              ),
            ),

            // Tier Cards disusun berurutan sesuai Mockup
            _buildTierCard(
              title: 'Bronze Member',
              benefits: [
                'Points Member',
                'Paket diskon 5%',
              ],
              bgColor: const Color(0xFFEBE6E1),
              borderColor: const Color(0xFFA67C52),
              titleColor: const Color(0xFF966C4D),
            ),

            _buildTierCard(
              title: 'Silver Member',
              benefits: [
                '1.5x Points multiplier',
                'Paket diskon 10%',
              ],
              bgColor: const Color(0xFFE8EBED),
              borderColor: const Color(0xFF95A5A6),
              titleColor: const Color(0xFF7F8C8D),
            ),

            _buildTierCard(
              title: 'Gold Member',
              benefits: [
                '1.5x Points multiplier',
                'Paket diskon 12%',
                'Diskon produk 5%',
              ],
              bgColor: const Color(0xFFF6EDE2),
              borderColor: const Color(0xFFD4B99F),
              titleColor: const Color(0xFFB59A7A), // Sedikit disesuaikan agar kontras
            ),

            _buildTierCard(
              title: 'Platinum Priority',
              benefits: [
                '2x Points multiplier',
                'Paket diskon 15%',
                'Diskon produk 10%',
              ],
              bgColor: const Color(0xFFE3D6CD),
              borderColor: const Color(0xFF693D2C),
              titleColor: const Color(0xFF693D2C),
            ),

            _buildTierCard(
              title: 'Diamond Priority',
              benefits: [
                '2x Points multiplier',
                'Paket diskon 15%',
                'Diskon produk 12%',
              ],
              bgColor: const Color(0xFFD4DEE2),
              borderColor: const Color(0xFF34495E),
              titleColor: const Color(0xFF34495E),
            ),
          ],
        ),
      ),
    );
  }
}