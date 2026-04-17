import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Model untuk Voucher
class VoucherModel {
  final String kode;
  final String nama;
  final String jenisDiskon;
  final String nilaiDiskon;
  final int minimal;
  final String tanggalSelesai;
  final bool layananTertentu;

  VoucherModel({
    required this.kode,
    required this.nama,
    required this.jenisDiskon,
    required this.nilaiDiskon,
    required this.minimal,
    required this.tanggalSelesai,
    required this.layananTertentu,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      kode: json['kode'] as String,
      nama: json['nama'] as String,
      jenisDiskon: (json['jenis_diskon'] as String?) ?? 'nominal',
      nilaiDiskon: json['nilai_diskon'] as String,
      minimal: json['minimal'] is int
          ? json['minimal'] as int
          : int.tryParse(json['minimal'].toString()) ?? 0,
      tanggalSelesai: json['selesai'] as String,
      layananTertentu: json['layanan_tertentu'] as bool,
    );
  }
}

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({Key? key}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  bool _isLoggedIn = false;
  
  // Warna Tema Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _accentColor = const Color(0xFFD4B89C); // Warna Aksen

  List<VoucherModel> _vouchers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() => _isLoggedIn = loggedIn);
    if (_isLoggedIn) {
      _fetchVouchers();
    }
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoading = true);
    final uri = Uri.parse('https://app.momnjo.com/api/voucher_api.php');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final dataList = body['data'] as List;
        setState(() {
          _vouchers = dataList
              .map((e) => VoucherModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        debugPrint('API error: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildUnauthenticatedUI();
    return _buildAuthenticatedUI();
  }

  Widget _buildAuthenticatedUI() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor:Colors.white, // Header warna peach/krim Tuan
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        title: Text(
          'Voucher Saya',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Tipis Asset Baru
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_garis.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          // Konten List Voucher
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : (_vouchers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 60,
                            color: const Color(0xFF693D2C).withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada voucher tersedia',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 100), // Ganjelan footer
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 20, bottom: 120), // Bottom padding gede biar ga ketutup menu home
                      itemCount: _vouchers.length,
                      itemBuilder: (context, index) {
                        final v = _vouchers[index];
                        final discountLabel = v.jenisDiskon == 'persen'
                            ? '${v.nilaiDiskon}% OFF'
                            : 'Rp ${v.nilaiDiskon}';
                        final branchTerm = v.layananTertentu
                            ? 'Hanya cabang tertentu'
                            : 'Semua cabang';
                        final terms =
                            '$branchTerm • Min. trx Rp ${v.minimal} • Tidak bisa digabung promo lain';
                        return _buildVoucherCard(
                          title: v.nama,
                          validity: v.tanggalSelesai,
                          terms: terms,
                          discountLabel: discountLabel,
                        );
                      },
                    )),
        ],
      ),
      // bottomNavigationBar sengaja dihapus karena udah numpang di HomeScreen
    );
  }

  Widget _buildVoucherCard({
    required String title,
    required String validity,
    required String terms,
    required String discountLabel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berlaku hingga: $validity',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9EAE1), // Peach tipis
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    discountLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            const Text(
              'Syarat & Ketentuan:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              terms,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Aksi pas mencet tombol Gunakan Sekarang
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDBA38C), // Warna peach button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Gunakan Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedUI() {
    return Scaffold(
      backgroundColor: _bgColor,
      // AppBar dihapus biar tampilannya clean polosan persis kayak Akses Booking & Member
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_garis.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9EAE1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Akses Voucher',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _primaryColor,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Silakan login terlebih dahulu untuk melihat daftar voucher Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDEBC9E), Color(0xFFC8A386)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC8A386).withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Login Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
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