import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    // Ambil data dari bookingData
    final selectedTreatments =
        bookingData['selectedTreatments'] as List<dynamic>? ?? [];
    final subcategoryName = bookingData['subcategoryName'] as String? ?? 'Unknown Category';
    final NumberFormat rupiahFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Hitung total harga
    int totalHarga = 0;
    for (var treatment in selectedTreatments) {
      int qty = treatment['qty'] ?? 0;
      int price = treatment['product_price'] ?? 0;
      totalHarga += qty * price;
    }

    // Tema Warna Desain Baru
    final Color primaryColor = const Color(0xFF693D2C); // Coklat Tua
    final Color bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
    final Color btnColor = const Color(0xFFDBA38C); // Warna Peach/Coral Tombol

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna solid krem biar header ga nyaru
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          'Booking Details', // Sesuai dengan text di mockup
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Tipis
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bookbg.png'), // Opsional kalau ada pattern
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LABEL SELECTED CATEGORY
                      Text(
                        'Selected Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // KARTU SELECTED CATEGORY
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9EAE1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.clean_hands_outlined, // Icon tangan ala spa
                                color: btnColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                subcategoryName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // LABEL SELECTED TREATMENTS
                      Text(
                        'Selected Treatments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // LIST TREATMENTS
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedTreatments.length,
                        itemBuilder: (context, index) {
                          final treatment = selectedTreatments[index] as Map<String, dynamic>;
                          final treatmentName = treatment['nama_item_master'] ?? 'Unknown Treatment';
                          final qty = treatment['qty'] ?? 0;
                          final price = treatment['product_price'] ?? 0;
                          // Jika kodingan sblmnya mengirim gambar, tangkap di sini. Jika tidak, pakai placeholder
                          final gambar = treatment['gambar']; 

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // GAMBAR TREATMENT
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: gambar != null && gambar.toString().isNotEmpty
                                      ? Image.network(
                                          'https://app.momnjo.com/assets/foto_item/$gambar',
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => _buildPlaceholderImage(),
                                        )
                                      : _buildPlaceholderImage(),
                                ),
                                const SizedBox(width: 16),
                                
                                // INFO TREATMENT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        treatmentName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Harga: ${rupiahFormat.format(price)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Qty: $qty',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // BOTTOM SECTION (TOTAL & BUTTONS)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BARIS TOTAL HARGA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            rupiahFormat.format(totalHarga),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // DUA TOMBOL PILIHAN
                      Row(
                        children: [
                          // TOMBOL CHOOSE OTHER TREATMENT (Outline)
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: primaryColor, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/kategori',
                                  arguments: bookingData,
                                );
                              },
                              child: const Text(
                                'Choose Other\nTreatment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // TOMBOL CONTINUE BOOKING (Solid)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
                                
                                if (!isLoggedIn) {
                                  Navigator.pushNamed(
                                    context,
                                    '/login',
                                    arguments: {
                                      'next': '/tambah',
                                      'bookingData': bookingData,
                                    },
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/tambah',
                                    arguments: bookingData,
                                  );
                                }
                              },
                              child: const Text(
                                'Continue\nBooking',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Helper buat gambar placeholder (Kalau dari sblmnya ga dikirim data gambarnya)
  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF382314), // Coklat gelap sesuai mockup
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'NO IMAGE\nAVAILABLE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD4B89C), // Warna emas/krem
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Icon(
            Icons.spa_outlined, // Icon pengganti siluet ibu & anak
            color: Color(0xFFD4B89C),
            size: 16,
          ),
          Text(
            'MomNJo',
            style: TextStyle(
              color: Color(0xFFD4B89C),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          )
        ],
      ),
    );
  }
}