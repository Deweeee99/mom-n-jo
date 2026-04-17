import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingDetailScreen({super.key, required this.bookingData});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // Kita bikin variable state buat nampung keranjang biar bisa diubah-ubah angkanya
  List<Map<String, dynamic>> _mutableTreatments = [];

  // Tema Warna Desain Baru
  final Color primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color btnColor = const Color(0xFFDBA38C); // Warna Peach/Coral Tombol

  @override
  void initState() {
    super.initState();
    // Copy data keranjang dari halaman sebelumnya ke variable lokal kita
    final initialTreatments = widget.bookingData['selectedTreatments'] as List<dynamic>? ?? [];
    _mutableTreatments = initialTreatments.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Fungsi buat nambahin Qty
  void _increaseQty(Map<String, dynamic> treatment) {
    setState(() {
      int currentQty = treatment['qty'] ?? 0;
      treatment['qty'] = currentQty + 1;
    });
  }

  // Fungsi buat ngurangin Qty
  void _decreaseQty(Map<String, dynamic> treatment) {
    setState(() {
      int currentQty = treatment['qty'] ?? 0;
      if (currentQty > 1) {
        treatment['qty'] = currentQty - 1;
      } else {
        // Kalo udah 1 dan dikurangin lagi, hapus barangnya dari keranjang!
        _mutableTreatments.remove(treatment);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // BRAY: KITA KELOMPOKKAN TREATMENT BERDASARKAN KATEGORI BIAR RAPI
    final Map<String, List<dynamic>> groupedTreatments = {};
    for (var t in _mutableTreatments) {
      String catName = t['subcategoryName'] ?? widget.bookingData['subcategoryName'] ?? 'Unknown Category';
      if (!groupedTreatments.containsKey(catName)) {
        groupedTreatments[catName] = [];
      }
      groupedTreatments[catName]!.add(t);
    }

    final NumberFormat rupiahFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Hitung total harga Real-Time
    int totalHarga = 0;
    for (var treatment in _mutableTreatments) {
      int qty = treatment['qty'] ?? 0;
      int price = treatment['product_price'] ?? 0;
      totalHarga += qty * price;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna solid krem
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          'Booking Details',
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
                image: AssetImage('assets/bookbg.png'), 
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: _mutableTreatments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 60, color: primaryColor.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('Keranjang kosong', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LOOPING PER KELOMPOK KATEGORI
                            ...groupedTreatments.entries.map((entry) {
                              final categoryName = entry.key;
                              final treatments = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. KARTU HEADER KATEGORI
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9EAE1), 
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: btnColor.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        // ---> BRAY: Ini Iconnya Udah Diganti Pake Aset Lu <---
                                        Image.asset(
                                          'assets/icon.png', 
                                          width: 24, 
                                          height: 24,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Icon(Icons.spa, color: primaryColor, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            categoryName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 2. LIST TREATMENT DI BAWAH KATEGORI TERSEBUT
                                  ...treatments.map((treatment) {
                                    final treatmentName = treatment['nama_item_master'] ?? 'Unknown Treatment';
                                    final qty = treatment['qty'] ?? 0;
                                    final price = treatment['product_price'] ?? 0;
                                    final gambar = treatment['gambar']; 

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8), 
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
                                          
                                          // INFO TREATMENT + TOMBOL PLUS MINUS
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  treatmentName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  rupiahFormat.format(price),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                
                                                // BRAY: INI FITUR TAMBAH KURANG QTY ESTETIK
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () => _decreaseQty(treatment),
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey.shade300),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(qty == 1 ? Icons.delete_outline : Icons.remove, size: 14, color: qty == 1 ? Colors.red : Colors.grey.shade700),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      child: Text(
                                                        '$qty',
                                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () => _increaseQty(treatment),
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: btnColor.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(Icons.add, size: 14, color: primaryColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  
                                  const SizedBox(height: 16), 
                                ],
                              );
                            }).toList(),
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
                                // Update keranjang terakhir sebelum pindah halaman
                                final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                                updatedBookingData['selectedTreatments'] = _mutableTreatments;

                                Navigator.pushNamed(
                                  context,
                                  '/kategori',
                                  arguments: updatedBookingData, 
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
                                if (_mutableTreatments.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Keranjang Anda kosong! Silakan pilih treatment.')),
                                  );
                                  return;
                                }

                                // Update keranjang terakhir sebelum checkout ke API form
                                final updatedBookingData = Map<String, dynamic>.from(widget.bookingData);
                                updatedBookingData['selectedTreatments'] = _mutableTreatments;

                                final prefs = await SharedPreferences.getInstance();
                                bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
                                
                                if (!isLoggedIn) {
                                  Navigator.pushNamed(
                                    context,
                                    '/login',
                                    arguments: {
                                      'next': '/tambah',
                                      'bookingData': updatedBookingData,
                                    },
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/tambah',
                                    arguments: updatedBookingData,
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF382314),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'NO IMAGE\nAVAILABLE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD4B89C),
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Icon(
            Icons.spa_outlined,
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