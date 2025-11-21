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

  TreatmentItem({
    required this.idItem,
    required this.namaItem,
    required this.satuan,
    required this.gambar,
    required this.price,
  });

  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem(
      idItem: json['id_item_master'].toString(),
      namaItem: json['nama_item_master'] ?? '',
      satuan: json['satuan'] ?? '',
      gambar: json['gambar'] ?? '',
      price: int.tryParse(json['product_price']?.toString() ?? '0') ?? 0,
    );
  }
}

class BookingTreatmentScreen extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;

  const BookingTreatmentScreen({
    Key? key,
    required this.subcategoryId,
    required this.subcategoryName,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _futureItems = fetchTreatmentItems(widget.subcategoryId);
    _futureItems.then((data) {
      _treatmentItems = data;
    });
  }

  // Cek status login, jika belum login langsung arahkan ke halaman login
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

  /// Fungsi mengambil data treatment dari server
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

  @override
  Widget build(BuildContext context) {
    // Diasumsikan user sudah login, karena _checkLogin() akan mengarahkan bila belum.
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Treatment - ${widget.subcategoryName}'),
        backgroundColor: const Color(0xFFAA6939), // Header senada dengan tombol
      ),
      body: FutureBuilder<List<TreatmentItem>>(
        future: _futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFAA6939)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada treatment tersedia.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final treatment = items[index];
              final qty = selectedItems[treatment.idItem] ?? 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    // Foto treatment
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://app.momnjo.com/assets/foto_item/${treatment.gambar}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ),
                    // Informasi treatment
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              treatment.namaItem,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFAA6939),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Satuan: ${treatment.satuan}'),
                            const SizedBox(height: 4),
                            Text(
                              _rupiahFormat.format(treatment.price),
                              style: const TextStyle(
                                color: Color(0xFFAA6939),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Kontrol jumlah (qty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _decrementQty(treatment.idItem),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Color(0xFFAA6939),
                            ),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _incrementQty(treatment.idItem),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFFAA6939),
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
      // Tombol "Lanjutkan Booking" di bagian bawah layar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAA6939), // Sesuai header
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Lanjutkan Booking'),
          onPressed: () {
            try {
              final selectedList = selectedItems.entries
                  .where((e) => e.value > 0)
                  .map((e) {
                    final treatment = _treatmentItems?.firstWhere(
                      (item) => item.idItem == e.key,
                      orElse: () => TreatmentItem(
                        idItem: e.key,
                        namaItem: 'Unknown',
                        satuan: '',
                        gambar: '',
                        price: 0,
                      ),
                    );
                    return {
                      'idItem': e.key,
                      'qty': e.value,
                      'nama_item_master':
                          treatment?.namaItem ?? 'Unknown Treatment',
                      'product_price': treatment?.price ?? 0,
                    };
                  })
                  .toList();

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
        ),
      ),
    );
  }
}
