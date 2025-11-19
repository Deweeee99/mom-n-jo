import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  int? branchId;

  // Formatter untuk Rupiah (tanpa angka di belakang koma)
  final NumberFormat _rupiahFormat =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Mengambil branchId dari ModalRoute setelah widget diinisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        setState(() {
          branchId = args;
        });
      }
    });
  }

  Future<List<dynamic>> fetchProducts(int branchId) async {
    final url = Uri.parse(
        'https://app.momnjo.com/api/get_products_by_category.php?branchId=$branchId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to load products. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (branchId == null) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD4B89C), Color(0xFF693D2C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: const Text('Produk Detail'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      /// Membuat AppBar dengan gradasi
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD4B89C), Color(0xFF693D2C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('Produk Detail'),
        centerTitle: true,
      ),

      /// Background layar dengan gradasi lembut
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF7F2), Color(0xFFF1EBE4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: fetchProducts(branchId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF693D2C),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Terjadi error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Tidak ada data produk.'),
              );
            }

            final products = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final namaItem =
                    product['nama_item_master']?.toString() ?? 'No Name';
                final satuan = product['satuan']?.toString() ?? '';
                final dynamic rawPrice = product['product_price'];
                final int priceInt =
                    int.tryParse(rawPrice?.toString() ?? '0') ?? 0;
                final harga = _rupiahFormat.format(priceInt);

                final baseUrl = 'https://app.momnjo.com/assets/foto_item/';
                final fileName = product['gambar']?.toString() ?? '';
                final fullImageUrl = '$baseUrl$fileName';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto Produk
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fullImageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),

                      // Info Produk
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaItem,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF693D2C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Satuan: $satuan',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.price_change_outlined,
                                    color: Color(0xFF693D2C),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    harga,
                                    style: const TextStyle(
                                      color: Color(0xFF693D2C),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Contoh jika ingin menambahkan "Detail" button di sisi kanan
                      /* Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF693D2C),
                          ),
                          onPressed: () {
                            // Aksi ketika ditekan
                          },
                          child: const Text(
                            'Detail',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ), */
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
