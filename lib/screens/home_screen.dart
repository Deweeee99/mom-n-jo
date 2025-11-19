import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Branch {
  final String id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id_gerai'].toString(),
      name: json['nama_gerai'],
    );
  }
}

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel untuk login check & nama user
  bool _isLoggedIn = false;
  String _fullname = '';

  // Banner images
  final List<String> banners = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];

  // Variabel untuk menampung data gerai secara dinamis
  List<Branch> _branches = [];

  // Variabel untuk bottom navigation
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cek data login & nama user
    _loadBranches(); // Ambil data gerai secara dinamis
  }

  /// Memuat status login + fullname dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedName = prefs.getString('fullname') ?? '';
    setState(() {
      _isLoggedIn = loggedIn;
      _fullname = savedName;
    });
  }

  // Fungsi ambil data branches/gerai dari server
  Future<List<Branch>> fetchBranches() async {
    try {
      final response = await http.get(
        Uri.parse('https://app.momnjo.com/api/list_gerai.php'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Branch.fromJson(json)).toList();
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception('Failed to load branches');
      }
    } catch (e) {
      print('Error fetching branches: $e');
      return [];
    }
  }

  /// Memanggil fetchBranches lalu disimpan di _branches
  Future<void> _loadBranches() async {
    final branches = await fetchBranches();
    setState(() {
      _branches = branches;
    });
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    // Bersihkan atau remove data lain jika perlu, lalu navigate ke login
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Ubah navigasi sesuai index
  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Stay on Home
        break;
      case 1:
        Navigator.pushNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushNamed(context, '/gift');
        break;
      case 3:
        Navigator.pushNamed(context, '/voucher');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12, // Bayangan halus
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _navigateToScreen(context, index);
          },
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text("Home"),
              selectedColor: const Color(0xFF693D2C),
            ),

            /// Booking
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              title: const Text("Booking"),
              selectedColor: const Color(0xFF693D2C),
            ),

            /// Gift
            SalomonBottomBarItem(
              icon: const Icon(Icons.card_giftcard_outlined),
              title: const Text("Gift"),
              selectedColor: const Color(0xFF693D2C),
            ),

            /// Voucher
            SalomonBottomBarItem(
              icon: const Icon(Icons.confirmation_number_outlined),
              title: const Text("Voucher"),
              selectedColor: const Color(0xFF693D2C),
            ),

            /// Profile
            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              selectedColor: const Color(0xFF693D2C),
            ),
          ],
        ),
      ),

      /// Menggunakan SingleChildScrollView agar header (kotak coklat) ikut discroll
      body: SingleChildScrollView(
        child: Column(
          children: [
            // BAGIAN HEADER: GRADIENT, LOGO, NOTIFICATION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4B89C), Color(0xFF693D2C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Row untuk logo & notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/momnjo_logo.png',
                          height: 60,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Welcome Text
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoggedIn ? 'Hi, $_fullname!' : 'Hi, Mom!',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'How can we help you today?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // JEDA ANTARA HEADER & KONTEN
            const SizedBox(height: 16),

            // Slider Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CarouselSlider(
                    items: banners
                        .map(
                          (banner) => Image.asset(
                            banner,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                        .toList(),
                    options: CarouselOptions(
                      height: 220,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      enlargeCenterPage: false,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Gambar promo
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/promo.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Gambar Statis - branches
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SizedBox(
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/txt-branches.png',
                    width: 190,
                    height: 70,
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Carousel cabang dinamis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _branches.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF693D2C),
                      ),
                    )
                  : CarouselSlider.builder(
                      itemCount: _branches.length,
                      itemBuilder:
                          (BuildContext context, int index, int realIndex) {
                        final branch = _branches[index];
                        // Ubah ID_gerai jadi int untuk navigasi
                        int branchId = int.tryParse(branch.id) ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/gerai_screen',
                                arguments: branchId,
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: Image.asset(
                                      'assets/darmawangsa.png',
                                      fit: BoxFit.cover,
                                      height: 110,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      branch.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF693D2C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 190,
                        enlargeCenterPage: true,
                        enableInfiniteScroll: true,
                        autoPlay: true,
                        scrollPhysics: const BouncingScrollPhysics(),
                      ),
                    ),
            ),

            // Gambar Statis - recommended
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SizedBox(
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/txt-recommended-service.png',
                    width: 250,
                    height: 70,
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // recommended Section using GridView
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: 5,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (BuildContext context, int index) {
                  List<String> branchNames = [
                    'Kids Treatment',
                    'Pregnancy Specialist',
                    'Postnatal Care',
                    'Baby Treatment',
                    'His and Her'
                  ];

                  List<String> branchImages = [
                    'assets/kid.png',
                    'assets/mom2be.png',
                    'assets/after-labour.png',
                    'assets/baby-massage.png',
                    'assets/him-her.png'
                  ];

                  List<int> branchIds = [
                    45, // Kids Treatment
                    43, // Pregnancy Specialist
                    22, // Postnatal Care
                    44, // Baby Treatment
                    41, // His and Her
                  ];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/produk_screen',
                        arguments: branchIds[index],
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.asset(
                              branchImages[index],
                              fit: BoxFit.cover,
                              height: 130,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              branchNames[index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF693D2C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),

            // Gambar Statis - Promo
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/home-service.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Spasi Bawah
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class BranchCard extends StatelessWidget {
  final String image;
  final String name;

  const BranchCard({
    super.key,
    required this.image,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gambar dengan border radius
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            image,
            width: 150,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF693D2C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
