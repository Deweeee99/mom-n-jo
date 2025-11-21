import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({Key? key, required this.bookingData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ambil data dari bookingData
    final selectedTreatments =
        bookingData['selectedTreatments'] as List<dynamic>;
    final subcategoryName = bookingData['subcategoryName'] as String;
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Booking - $subcategoryName'),
        backgroundColor: const Color(
          0xFFAA6939,
        ), // Header dengan warna coklat AA6939
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rincian Booking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.category,
                      color: Color(0xFFAA6939),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subcategoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Treatment yang Dipilih:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: selectedTreatments.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Colors.grey),
                itemBuilder: (context, index) {
                  final treatment =
                      selectedTreatments[index] as Map<String, dynamic>;
                  final treatmentName =
                      treatment['nama_item_master'] ?? 'Unknown Treatment';
                  final qty = treatment['qty'] ?? 0;
                  final price = treatment['product_price'] ?? 0;
                  return ListTile(
                    leading: const Icon(
                      Icons.medical_services,
                      color: Color(0xFFAA6939),
                    ),
                    title: Text(
                      treatmentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Harga: ${rupiahFormat.format(price)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Qty: $qty',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rupiahFormat.format(qty * price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFAA6939),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Harga:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rupiahFormat.format(totalHarga),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAA6939),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Dua pilihan: Pilih Treatment Lainnya dan Lanjutkan Pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Pilih Treatment Lainnya
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Background tetap orange
                      foregroundColor: Colors.white, // Teks putih
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Navigasi ke layar daftar kategori khusus ("/kategori")
                      // Data booking (treatment yang sudah dipilih) dikirim agar tidak hilang
                      Navigator.pushNamed(
                        context,
                        '/kategori',
                        arguments: bookingData,
                      );
                    },
                    child: const Text(
                      'Pilih Treatment Lainnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol Lanjutkan Pembayaran
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFAA6939,
                      ), // Background coklat AA6939
                      foregroundColor: Colors.white, // Teks putih
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
                      if (!isLoggedIn) {
                        // Jika belum login, arahkan ke LoginScreen dengan parameter next ke /tambah
                        Navigator.pushNamed(
                          context,
                          '/login',
                          arguments: {
                            'next': '/tambah',
                            'bookingData': bookingData,
                          },
                        );
                      } else {
                        // Jika sudah login, langsung ke halaman pembayaran (TambahScreen)
                        Navigator.pushNamed(
                          context,
                          '/tambah',
                          arguments: bookingData,
                        );
                      }
                    },
                    child: const Text(
                      'Lanjutkan Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
