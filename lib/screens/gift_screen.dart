import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
                      'Silakan login terlebih dahulu untuk mengakses fitur Activity, Redeem, dan History.',
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
        backgroundColor: const Color(0xFFFDF8F4), 
        appBar: AppBar(
          backgroundColor: const Color(0xFFFDF8F4), 
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Activity', // Diubah sesuai Mockup
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF9B5D4C)),
              onPressed: _showInfoDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: const Color(0xFFFDF8F4),
              child: const TabBar(
                labelColor: Color(0xFF9B5D4C), 
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF9B5D4C),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  Tab(text: 'Activity'), // Tab 1
                  Tab(text: 'Redeem'),   // Tab 2
                  Tab(text: 'History'),  // Tab 3
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _ActivityTabWidget(), // Panggil Widget Baru buat Tab Activity
            _RedeemTabWidget(),   
            Center(
              child: Text(
                'Belum ada riwayat transaksi',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
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
          'Fitur ini memungkinkan Anda untuk melihat aktivitas treatment yang sedang berjalan (Activity), tukar kode promo (Redeem), dan riwayat masa lalu (History).',
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

// =========================================================================
// WIDGET BARU: TAB ACTIVITY (NARIK DATA API TAPI DI-FILTER KHUSUS ONGOING)
// =========================================================================
class _ActivityTabWidget extends StatefulWidget {
  const _ActivityTabWidget();

  @override
  State<_ActivityTabWidget> createState() => _ActivityTabWidgetState();
}

class _ActivityTabWidgetState extends State<_ActivityTabWidget> {
  bool _isLoading = true;
  List<dynamic> _activityList = [];
  String _customerName = "Member";

  @override
  void initState() {
    super.initState();
    _fetchActivityData();
  }

  Future<void> _fetchActivityData() async {
    final prefs = await SharedPreferences.getInstance();
    final String idCustomer = prefs.getString('id_customer') ?? '';
    final String fullName = prefs.getString('fullname') ?? 'Member';

    setState(() {
      _customerName = fullName;
    });

    if (idCustomer.isEmpty) return;

    try {
      // BRAY: Kita pake API yang sama kayak History Screen
      final url = Uri.parse('https://app.momnjo.com/api/get_history.php?id_customer=$idCustomer');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // ---> FILTERING AJAIB <---
        // Kita cuma ambil yang statusnya udah confirm, verified, ongoing, atau completed
        final filteredData = data.where((item) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          return status == 'ongoing' || 
                 status == 'completed' || 
                 status == 'verified' || 
                 status == 'confirmed' || 
                 status == 'open';
        }).toList();

        setState(() {
          _activityList = filteredData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Desain Card Plek-Ketiplek Mockup
  Widget _buildActivityCard(Map<String, dynamic> trx) {
    final String statusRaw = (trx['status'] ?? '').toString().toLowerCase();
    
    // Parse Tanggal & Waktu
    DateTime bookingStart;
    try {
      bookingStart = DateTime.parse("${trx['tgl_dokumen']} ${trx['jam']}");
    } catch (e) {
      bookingStart = DateTime.now();
    }
    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(bookingStart);

    // Variabel Styling Status
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;
    Widget actionWidget;

    // Logika Status Berdasarkan Mockup
    if (statusRaw == 'ongoing') {
      badgeBgColor = const Color(0xFFFDECDA); // Orange pudar
      badgeTextColor = const Color(0xFFD68A59); // Orange solid
      badgeText = "Ongoing";
      actionWidget = Text(
        "Treatment in Progress",
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      );
    } else if (statusRaw == 'completed') {
      badgeBgColor = Colors.grey.shade200;
      badgeTextColor = Colors.grey.shade700;
      badgeText = "Completed";
      actionWidget = Text(
        "Treatment Finished",
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
      );
    } else {
      // Default untuk Confirmed/Verified (Sesuai Mockup: "Scheduled")
      badgeBgColor = const Color(0xFFE3F0FF); // Biru pudar
      badgeTextColor = const Color(0xFF4A85D9); // Biru solid
      badgeText = "Scheduled";
      actionWidget = OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF693D2C),
          side: const BorderSide(color: Color(0xFF693D2C), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {}, // Nanti diisi aksi lihat jadwal
        child: const Text('View Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD (Icon + Judul + Badge Status)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Kotak Kiri
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9EAE1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icon.png', // Aset Ikon Tuan
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa_outlined, color: Color(0xFF693D2C)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Judul Treatment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trx['deskripsi'] ?? 'Paket Treatment',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge Status (Kanan Atas)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // TABEL INFORMASI DETAIL
          _buildDetailRow('Member', _customerName),
          const SizedBox(height: 6),
          _buildDetailRow('Branch', trx['gerai'] ?? 'Cabang MomNJo'),
          const SizedBox(height: 6),
          _buildDetailRow('Date/Time', formattedDate),
          const SizedBox(height: 6),
          _buildDetailRow('Therapist', trx['id_terapis']?.toString().isNotEmpty == true ? trx['id_terapis'] : 'Any Therapist'),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          
          // FOOTER CARD (Status Kiri & Aksi Kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Status', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // Action Widget (Bisa Teks "Treatment in Progress" atau Tombol "View Schedule")
              actionWidget,
            ],
          ),
        ],
      ),
    );
  }

  // Helper pembuat baris informasi tabel
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF693D2C)));
    }

    if (_activityList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustrasi Kosong sesuai mockup
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF9EAE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pregnant_woman_rounded, size: 60, color: Color(0xFFDBA38C)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No ongoing activities yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _activityList.length,
      itemBuilder: (context, index) {
        return _buildActivityCard(_activityList[index]);
      },
    );
  }
}


// =========================================================================
// WIDGET LAMA: REDEEM TAB
// =========================================================================
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
    final primaryBrown = const Color(0xFF9B5D4C); 

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tukarkan Kode Hadiah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBrown,
            ),
          ),
          const SizedBox(height: 24),
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