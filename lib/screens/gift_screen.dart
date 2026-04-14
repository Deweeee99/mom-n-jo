import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  bool _isLoggedIn = false;

  // Warna Tema Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _btnColor = const Color(0xFFDBA38C); // Warna Peach Tombol

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildAuthenticatedUI() : _buildUnauthenticatedUI();
  }

  Widget _buildUnauthenticatedUI() {
    return Scaffold(
      backgroundColor: _bgColor,
      // AppBar dihapus biar tampilannya clean polosan persis kayak Akses Booking
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_landing.png'),
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
                        Icons.card_giftcard_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Akses Member',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _primaryColor,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Silakan login terlebih dahulu untuk mengakses fitur informasi member, purchase, dan redeem.',
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

  Widget _buildAuthenticatedUI() {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.white, // Sesuaikan dengan screenshot lu yang latarnya putih bersih
        appBar: AppBar(
          backgroundColor: Colors.white, // AppBar dibikin putih bersih
          elevation: 0, // Tanpa bayangan
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Informasi Member',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500, // Agak tipis sesuai desain
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF9B5D4C)), // Warna icon info
              onPressed: _showInfoDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF9B5D4C), // Coklat kemerahan
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF9B5D4C),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  Tab(text: 'Purchase'),
                  Tab(text: 'Redeem'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background Tipis
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg_landing.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
              ),
            ),
            
            // Isi Konten per Tab
            const TabBarView(
              children: [
                // Tab 1: Purchase
                Center(
                  child: Text(
                    'Belum ada riwayat pembelian',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                
                // Tab 2: Redeem (Sesuai Desain Asli)
                _RedeemTabWidget(),
                
                // Tab 3: History
                Center(
                  child: Text(
                    'Belum ada riwayat transaksi',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Info Member', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: const Text(
          'Fitur ini memungkinkan Anda untuk melihat riwayat pembelian paket/gift dan informasi terkait member.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _btnColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Widget Khusus buat nampilin form Redeem
class _RedeemTabWidget extends StatefulWidget {
  const _RedeemTabWidget();

  @override
  State<_RedeemTabWidget> createState() => _RedeemTabWidgetState();
}

class _RedeemTabWidgetState extends State<_RedeemTabWidget> {
  final TextEditingController _redeemController = TextEditingController();

  void _submitRedeem() {
    if (_redeemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan kode hadiah terlebih dahulu')),
      );
      return;
    }
    // TODO: Aksi tembak API redeem di sini
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengecek kode: ${_redeemController.text}...')),
    );
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryBrown = const Color(0xFF9B5D4C); // Coklat yang sesuai desain lu

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Judul
          Text(
            'Tukarkan Kode Hadiah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBrown,
            ),
          ),
          const SizedBox(height: 24),

          // Field Masukkan Kode
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: TextField(
              controller: _redeemController,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.card_giftcard_outlined,
                  color: primaryBrown,
                  size: 22,
                ),
                hintText: 'Masukkan Kode',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Tukarkan Sekarang
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _submitRedeem,
              child: const Text(
                'Tukarkan Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Teks keterangan di bawah
          Text(
            '*Kode hadiah bisa didapatkan dari berbagai promo yang\ntersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}