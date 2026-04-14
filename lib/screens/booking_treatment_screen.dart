import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model untuk Treatment Item
class TreatmentItem {
  final String idItem;
  final String namaItem;
  final String satuan;
  final String gambar;
  final int price;
  final String durasi;
  // final String deskripsi;

  TreatmentItem({
    required this.idItem,
    required this.namaItem,
    required this.satuan,
    required this.gambar,
    required this.price,
    required this.durasi,
    // required this.deskripsi,
  });

  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem(
      idItem: json['id_item_master'].toString(),
      namaItem: json['nama_item_master'] ?? '',
      satuan: json['satuan'] ?? '',
      gambar: json['gambar'] ?? '',
      price: int.tryParse(json['product_price']?.toString() ?? '0') ?? 0,
      // Ngambil durasi dan deskripsi dari API. 
      // Kalau API belum ngirim, otomatis pake '80 min' dan teks contoh biar UI tetap cantik.
      durasi: json['durasi']?.toString() ?? '80 min',
      // deskripsi: json['deskripsi'] ?? json['description'] ?? 'Detail treatment belum tersedia. Nikmati layanan terbaik dari kami.',
    );
  }
}

class BookingTreatmentScreen extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;

  const BookingTreatmentScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<BookingTreatmentScreen> createState() => _BookingTreatmentScreenState();
}

class _BookingTreatmentScreenState extends State<BookingTreatmentScreen> {
  late Future<List<TreatmentItem>> _futureItems;
  final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Map untuk menyimpan jumlah (qty) item yang dipilih, key = idItem
  Map<String, int> selectedItems = {};

  // Simpan list treatment lengkap agar bisa diakses saat submit
  List<TreatmentItem>? _treatmentItems;

  // Warna Tema Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _btnColor = const Color(0xFFDBA38C); // Warna Peach/Coral Tombol Bawah

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _futureItems = fetchTreatmentItems(widget.subcategoryId);
    _futureItems.then((data) {
      setState(() {
        _treatmentItems = data;
      });
    });
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/login',
          arguments: {
            'next': '/booking_treatment',
            'subcategoryId': widget.subcategoryId,
            'subcategoryName': widget.subcategoryName,
          },
        );
      });
    }
  }

  Future<List<TreatmentItem>> fetchTreatmentItems(int subcategoryId) async {
    final url = Uri.parse(
      'https://app.momnjo.com/api/get_items_by_subcategory.php?subcatId=$subcategoryId',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TreatmentItem.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data treatment: ${response.statusCode}');
    }
  }

  void _incrementQty(String itemId) {
    setState(() {
      selectedItems[itemId] = (selectedItems[itemId] ?? 0) + 1;
    });
  }

  void _decrementQty(String itemId) {
    setState(() {
      if ((selectedItems[itemId] ?? 0) > 0) {
        selectedItems[itemId] = selectedItems[itemId]! - 1;
      }
    });
  }

  // Fungsi tambahan buat ngitung total harga real-time
  int _getTotalPrice() {
    if (_treatmentItems == null) return 0;
    int total = 0;
    selectedItems.forEach((key, qty) {
      try {
        final item = _treatmentItems!.firstWhere((element) => element.idItem == key);
        total += item.price * qty;
      } catch (e) {
        // Item tidak ditemukan
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna lebih tebal dari background biar ga nyaru
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        title: Text(
          'Select Treatment - ${widget.subcategoryName}', // Sesuaikan dengan mockup lu
          style: TextStyle(
            color: _primaryColor,
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
                image: AssetImage('assets/bookbg.png'), // Pastiin file ada
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          // List Treatment
          SafeArea(
            child: FutureBuilder<List<TreatmentItem>>(
              future: _futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada treatment tersedia.',
                      style: TextStyle(color: _primaryColor, fontSize: 16),
                    ),
                  );
                }

                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 120, left: 20, right: 20), // Bottom padding gede biar ga ketutup bar
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final treatment = items[index];
                    final qty = selectedItems[treatment.idItem] ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gambar Treatment
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://app.momnjo.com/assets/foto_item/${treatment.gambar}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.spa_outlined, color: _primaryColor.withOpacity(0.5)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          // Informasi Treatment
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Baris Judul dan Harga
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        treatment.namaItem,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _rupiahFormat.format(treatment.price),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                
                                // Durasi (Diganti dari satuan ke durasi)
                                Text(
                                  'Durasi: ${treatment.durasi}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                
                                // Deskripsi Treatment (Baru ditambahkan)
                                // Text(
                                //    treatment.deskripsi,
                                //   style: TextStyle(
                                //     fontSize: 11,
                                //     color: Colors.grey.shade600,
                                //     height: 1.3,
                                //   ),
                                //   maxLines: 2,
                                //   overflow: TextOverflow.ellipsis,
                                // ),
                                
                                const SizedBox(height: 8),
                                
                                // Tombol Plus Minus Estetik (Ala Desain)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tombol Minus (Outline)
                                      InkWell(
                                        onTap: () => _decrementQty(treatment.idItem),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.remove, size: 18, color: Colors.grey.shade700),
                                        ),
                                      ),
                                      
                                      // Angka Qty
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      
                                      // Tombol Plus (Solid)
                                      InkWell(
                                        onTap: () => _incrementQty(treatment.idItem),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC48671), // Warna solid kecoklatan
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // BOTTOM BAR (TOTAL HARGA & TOMBOL LANJUT)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Teks Total Selected
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Selected:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _rupiahFormat.format(_getTotalPrice()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    // Tombol Continue Booking
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _btnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // Melengkung pil
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        try {
                          final selectedList =
                              selectedItems.entries.where((e) => e.value > 0).map((e) {
                            final treatment = _treatmentItems?.firstWhere(
                              (item) => item.idItem == e.key,
                              orElse: () => TreatmentItem(
                                idItem: e.key,
                                namaItem: 'Unknown',
                                satuan: '',
                                gambar: '',
                                price: 0,
                                durasi: '',
                                // deskripsi: '',
                              ),
                            );

                            return {
                              'idItem': int.tryParse(e.key) ?? e.key,
                              'nama_item_master': treatment?.namaItem ?? 'Unknown Treatment',
                              'qty': e.value,
                              'product_price': treatment?.price ?? 0,
                            };
                          }).toList();

                          if (selectedList.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pilih minimal 1 treatment')),
                            );
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            '/booking_detail',
                            arguments: {
                              'selectedTreatments': selectedList,
                              'subcategoryId': widget.subcategoryId,
                              'subcategoryName': widget.subcategoryName,
                            },
                          );
                        } catch (e, s) {
                          debugPrint("Error in onPressed: $e\n$s");
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Continue Booking',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
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