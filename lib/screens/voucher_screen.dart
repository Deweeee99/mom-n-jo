import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
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
  final int _currentIndex = 3;
  final Color _primaryColor = const Color(0xFF9B5D4C);
  final Color _accentColor = const Color(0xFFD4B89C);

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

  void _navigateToScreen(BuildContext context, int index) {
    if (index == _currentIndex) return;
    const routes = ['/home', '/booking', '/gift', '/voucher', '/profile'];
    Navigator.pushNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildUnauthenticatedUI();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Saya'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_vouchers.isEmpty
              ? const Center(child: Text('Tidak ada voucher tersedia'))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16),
                  itemCount: _vouchers.length,
                  itemBuilder: (context, index) {
                    final v = _vouchers[index];
                    final discountLabel = v.jenisDiskon == 'persen'
                        ? '${v.nilaiDiskon}% OFF'
                        : 'Rp ${v.nilaiDiskon}';
                    final branchTerm = v.layananTertentu
                        ? 'Hanya tersedia di cabang tertentu'
                        : 'Semua cabang';
                    final terms =
                        '$branchTerm • Minimum transaksi Rp ${v.minimal} • Tidak bisa digabung dengan promo lain';
                    return _buildVoucherCard(
                      title: v.nama,
                      validity: v.tanggalSelesai,
                      terms: terms,
                      discountLabel: discountLabel,
                    );
                  },
                )),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildVoucherCard({
    required String title,
    required String validity,
    required String terms,
    required String discountLabel,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berlaku hingga: $validity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    discountLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Syarat & Ketentuan:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              terms,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Gunakan Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5E6E0), Color(0xFFFEF9F5)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/auth_required.png',
                  height: 200,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.lock_person,
                    size: 150,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Akses Voucher',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Silakan login untuk melihat voucher',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Login Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => _navigateToScreen(context, index),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(icon: Icon(Icons.home), title: Text('Home')),
          SalomonBottomBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              title: Text('Booking')),
          SalomonBottomBarItem(
              icon: Icon(Icons.card_giftcard_outlined), title: Text('Gift')),
          //
          SalomonBottomBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              title: Text('Voucher')),
          SalomonBottomBarItem(
              icon: Icon(Icons.person_outline), title: Text('Profile')),
        ],
      ),
    );
  }
}
