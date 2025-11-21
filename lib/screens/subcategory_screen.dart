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
    Key? key,
    required this.categoryId,
    this.bookingData,
  }) : super(key: key);

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  late Future<List<Subcategory>> _futureSubcategories;

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
      appBar: AppBar(
        title: const Text('Pilih Sub-Kategori'),
        backgroundColor: const Color(0xFFAA6939),
      ),
      body: FutureBuilder<List<Subcategory>>(
        future: _futureSubcategories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFAA6939)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada sub-kategori'));
          }
          final subcategories = snapshot.data!;
          return ListView.builder(
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcat = subcategories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    subcat.namaSubkategori,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAA6939),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFAA6939),
                  ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
