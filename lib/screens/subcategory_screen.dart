import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Subcategory {
  final String idSubKat;
  final String namaSubkategori;

  Subcategory({required this.idSubKat, required this.namaSubkategori});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      idSubKat: json['id_sub_kat'].toString(),
      namaSubkategori: json['nama_subkategori'],
    );
  }
}

class SubcategoryScreen extends StatefulWidget {
  final int categoryId;
  final Map<String, dynamic>? bookingData;

  const SubcategoryScreen({
    super.key,
    required this.categoryId,
    this.bookingData,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  late Future<List<Subcategory>> _futureSubcategories;
  
  // Warna Tema Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _iconBgColor = const Color(0xFFF5E6E0); // Warna alas ikon

  @override
  void initState() {
    super.initState();
    _futureSubcategories = fetchSubcategories(widget.categoryId);
  }

  Future<List<Subcategory>> fetchSubcategories(int categoryId) async {
    debugPrint("DEBUG: fetchSubcategories => categoryId=$categoryId");
    final url = Uri.parse(
      'https://app.momnjo.com/api/get_subcategories_by_category.php?catId=$categoryId',
    );
    debugPrint("DEBUG: subcategory URL => $url");
    final response = await http.get(url);
    debugPrint("DEBUG: subcategory response => ${response.body}");
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Subcategory.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat sub-kategori: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // extendBodyBehindAppBar dihapus biar header punya ruang sendiri (default)
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna lebih tebal dari background biar ga nyaru
        elevation: 2, // Dikasih bayangan tipis biar kepisah dari body
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor), // Tombol back warna coklat
        title: Text(
          'Pilih Sub-Kategori', // Dibalikin ke default
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Tipis (Biar seragam sama halaman sebelumnya)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bookbg.png'), // Sesuaikan nama file lu
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),

          // Konten List SubKategori
          SafeArea(
            child: FutureBuilder<List<Subcategory>>(
              future: _futureSubcategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: _primaryColor),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada sub-kategori',
                      style: TextStyle(color: _primaryColor, fontSize: 16),
                    ),
                  );
                }
                
                final subcategories = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcat = subcategories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/booking_treatment',
                            arguments: {
                              'subcategoryId': int.parse(subcat.idSubKat),
                              'subcategoryName': subcat.namaSubkategori,
                              'bookingData': widget.bookingData,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20), // Melengkung pil
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
                              // Ikon di kiri (Gaya Desain)
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _iconBgColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  // Ikon default karena dari API nggak ada gambar
                                  Icons.spa_outlined, 
                                  color: _primaryColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Teks Subkategori
                              Expanded(
                                child: Text(
                                  subcat.namaSubkategori,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              
                              // Arrow ke kanan
                              Icon(
                                Icons.chevron_right_rounded,
                                color: _primaryColor,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}