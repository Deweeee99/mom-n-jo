import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  bool _isLoggedIn = false;
  final int _currentIndex = 2;
  final Color _primaryColor = const Color(0xFF9B5D4C);
  final Color _accentColor = const Color(0xFFD4B89C);

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

  void _navigateToScreen(BuildContext context, int index) {
    if (index == _currentIndex) return;

    final routes = [
      '/home',
      '/booking',
      '/gift',
      '/voucher',
      '/profile',
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? _buildAuthenticatedUI() : _buildUnauthenticatedUI();
  }

  Widget _buildUnauthenticatedUI() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Informasi Member',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
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
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.lock_person,
                    size: 150,
                    color: _primaryColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Akses Member MomnJo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Silakan login terlebih dahulu untuk mengakses fitur member eksklusif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
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
    );
  }

  Widget _buildAuthenticatedUI() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Informasi Member',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: _primaryColor),
              onPressed: _showInfoDialog,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                TabBar(
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _primaryColor,
                  tabs: const [
                    Tab(text: 'Purchase'),
                    Tab(text: 'Redeem'),
                    Tab(text: 'History'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _PurchaseTab(),
            _RedeemTab(),
            _HistoryTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
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
          )
        ],
      ),
      child: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => _navigateToScreen(context, index),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            title: const Text("Booking"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.card_giftcard_outlined),
            title: const Text("Gift"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.confirmation_number_outlined),
            title: const Text("Voucher"),
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text("Profile"),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Member'),
        content: const Text(
          'Fitur ini memungkinkan Anda untuk melihat riwayat pembelian, menukarkan kode hadiah, dan melihat histori transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _PurchaseTab extends StatelessWidget {
  const _PurchaseTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Belum ada riwayat pembelian',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Belum ada riwayat transaksi',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class _RedeemTab extends StatefulWidget {
  const _RedeemTab();

  @override
  State<_RedeemTab> createState() => __RedeemTabState();
}

class __RedeemTabState extends State<_RedeemTab> {
  final _codeController = TextEditingController();
  final Color _primaryColor = const Color(0xFF9B5D4C);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tukarkan Kode Hadiah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Masukkan Kode',
              prefixIcon: Icon(Icons.card_giftcard, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _redeemCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tukarkan Sekarang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '*Kode hadiah bisa didapatkan dari berbagai promo yang tersedia',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _redeemCode() {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan kode terlebih dahulu')),
      );
      return;
    }
    // Implement redeem logic here
  }
}
