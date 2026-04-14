import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart'; // <-- Package animasi kita balikin!
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import halaman lain biar bisa dipanggil di dalam body tanpa pindah rute
import 'booking_screen.dart';
import 'gift_screen.dart';
import 'voucher_screen.dart';
import 'profile_screen.dart';

/// Model Branch
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

/// Model Category
class Category {
  final String id;
  final String name;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id_kategori'].toString(),
      name: json['nm_kategori'],
      image: json['gambar_kategori'],
    );
  }
}

/// Fungsi membuka URL eksternal
Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

/// Fungsi navigasi dengan loading (Kita pake ini lagi biar ga double footer)
void navigateWithLoading(BuildContext context, String routeName,
    {Object? arguments, bool replace = false}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoadingDialog(),
  );

  Future.delayed(const Duration(milliseconds: 300), () {
    Navigator.pop(context); // hapus loading dialog
    if (replace) {
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    } else {
      Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  });
}

/// Loading dialog widget
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: HourglassLoading());
  }
}

class HourglassLoading extends StatefulWidget {
  const HourglassLoading({super.key});
  @override
  _HourglassLoadingState createState() => _HourglassLoadingState();
}

class _HourglassLoadingState extends State<HourglassLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _animation = Tween<double>(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 71, 60, 60),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: RotationTransition(
          turns: _animation,
          child: SizedBox(
            width: 50,
            height: 70,
            child: CustomPaint(painter: HourglassPainter()),
          ),
        ),
      ),
    );
  }
}

class HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    // Gambar bagian atas
    Path topPath = Path();
    topPath.moveTo(0, 0);
    topPath.quadraticBezierTo(size.width / 2, size.height * 0.5, size.width, 0);
    topPath.lineTo(size.width, size.height * 0.5);
    topPath.quadraticBezierTo(
        size.width / 2, size.height * 0.25, 0, size.height * 0.5);
    topPath.close();
    canvas.drawPath(topPath, paint);
    // Gambar bagian bawah
    Path bottomPath = Path();
    bottomPath.moveTo(0, size.height * 0.5);
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.75, size.width, size.height * 0.5);
    bottomPath.lineTo(size.width, size.height);
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.5, 0, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;
  String _fullname = '';
  final List<String> banners = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png'
  ];
  List<Branch> _branches = [];
  List<Category> _categories = [];
  int _currentIndex = 0;
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBranches();
    _loadCategories();
    _fetchNotifCount();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedName = prefs.getString('fullname') ?? '';
    setState(() {
      _isLoggedIn = loggedIn;
      _fullname = savedName;
    });
  }

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

  Future<void> _loadBranches() async {
    final branches = await fetchBranches();
    setState(() {
      _branches = branches;
    });
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://app.momnjo.com/api/list_kategori.php'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<void> _loadCategories() async {
    final categories = await fetchCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _fetchNotifCount() async {
    final prefs = await SharedPreferences.getInstance();
    final idCustomer = prefs.getString('id_customer') ?? '';
    if (idCustomer.isNotEmpty) {
      final url = Uri.parse(
          "https://app.momnjo.com/api/get_notifications.php?id_customer=$idCustomer");
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _notifCount = data.length;
          });
        }
      } catch (e) {
        print("Error fetching notif count: $e");
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    navigateWithLoading(context, '/login', replace: true);
  }

  // Widget bantuan untuk judul: Padding dikurangin abis-abisan biar mepet banget
  Widget _buildSectionTitle(String imagePath, {bool showGirlIcon = false}) {
    return Padding(
      // Top 0 & Bottom 4 biar bener-bener rapat ke card di bawahnya
      padding: const EdgeInsets.only(top: 0, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 40, // Tinggi diturunin dikit biar keliatan rapet
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              'Aset Gambar Hilang', 
              style: TextStyle(color: Color(0xFF693D2C), fontWeight: FontWeight.bold),
            ),
          ),
          
          if (showGirlIcon) ...[
            const SizedBox(width: 6),
            Image.asset(
              'assets/images/icon_perempuan.jpg',
              width: 35, // Dikecilin proporsional
              height: 35,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.face_retouching_natural, color: Color(0xFF8B9A76), size: 26),
            )
          ],
        ],
      ),
    );
  }

  // FUNGSI INI ADALAH BODY UTAMA UNTUK HOME
  Widget _buildHomeBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFA67C65), 
                      Color(0xFF693D2C), 
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5), // Bawah dikurangin
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo_momnjo.png', 
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => const Text('mom n jo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/ListNotifScreen');
                                    },
                                  ),
                                  if (_notifCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB5937B), 
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Text(
                                          '$_notifCount',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                                onPressed: () {
                                  // Aksi pencarian
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoggedIn ? 'Hi, $_fullname!' : 'Hi, Mom!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2), // Rapatkan ke subtitle
                          const Text(
                            'How can we help you today?',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 15), // Dikecilin biar banner naik

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CarouselSlider(
                            items: banners.map((banner) {
                              return Image.asset(
                                banner,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                                ),
                              );
                            }).toList(),
                            options: CarouselOptions(
                              height: 180,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 4),
                              enlargeCenterPage: false,
                              viewportFraction: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8), // Sedikit jarak dari banner atas ke judul

          _buildSectionTitle('assets/txt-recommended-service.png', showGirlIcon: true),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _categories.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF693D2C)))
                : GridView.builder(
                    itemCount: _categories.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 12, // Dikecilin biar antar card makin deket
                      childAspectRatio: 0.85, 
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final category = _categories[index];
                      final baseUrl = 'https://app.momnjo.com/assets/foto_kategori/';
                      final fullImageUrl = '$baseUrl${category.image}';
                      
                      return GestureDetector(
                        onTap: () {
                          final categoryId = int.tryParse(category.id.toString()) ?? 0;
                          navigateWithLoading(context, '/subcategory', arguments: {
                            'categoryId': categoryId,
                            'bookingData': null,
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.spa_outlined, size: 40, color: Color(0xFFB5937B)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Margin text di card dipres
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF9EAE1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.face_retouching_natural, color: Color(0xFFB5937B), size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF693D2C),
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 5), // Sangat rapat

          _buildSectionTitle('assets/txt-branches.png', showGirlIcon: false),

          Padding(
            padding: const EdgeInsets.only(bottom: 0), // Pangkas habis
            child: _branches.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF693D2C)))
                : CarouselSlider.builder(
                    itemCount: _branches.length,
                    itemBuilder: (BuildContext context, int index, int realIndex) {
                      final branch = _branches[index];
                      int branchId = int.tryParse(branch.id) ?? 0;
                      return GestureDetector(
                        onTap: () {
                          navigateWithLoading(context, '/gerai_screen', arguments: branchId);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Vertical dikecilin banget
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.asset(
                                    'assets/darmawangsa.png', 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  alignment: Alignment.centerLeft, 
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    branch.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF693D2C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 180, // Tinggi slider dikurangin dikit
                      enlargeCenterPage: true,
                      enableInfiniteScroll: true,
                      autoPlay: true,
                      viewportFraction: 0.75, 
                      scrollPhysics: const BouncingScrollPhysics(),
                    ),
                  ),
          ),

          const SizedBox(height: 5), // Sangat rapat

          _buildSectionTitle('assets/txt-home-service.png', showGirlIcon: true),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/home-service.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: const Color(0xFFDEBC9E),
                    child: const Center(child: Text("HOME SERVICE Banner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ),
          ),
          
          // Ganjelan masih disisakan biar ga mentok footer yang melar
          const SizedBox(height: 120), 
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List halaman untuk navigasi internal (Shell)
    // Pastikan kelas-kelas ini (BookingScreen, dkk) beneran ada dari import di atas.
    final List<Widget> pages = [
      _buildHomeBody(),         // Index 0: Tampilan Utama Home
      const BookingScreen(),    // Index 1: Schedule
      const GiftScreen(),       // Index 2: Package
      const VoucherScreen(),    // Index 3: Ticket
      const ProfileScreen(),    // Index 4: Profile
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      extendBody: true, 
      // Footer kembali menggunakan SalomonBottomBar biar animasinya idup lagi
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SalomonBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index; // Cukup ganti index, nggak usah push route lagi!
              });
            },
            selectedItemColor: const Color(0xFF693D2C),
            unselectedItemColor: Colors.grey.shade600,
            itemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_filled),
                title: const Text("Home"),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                title: const Text("Schedule"), 
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.card_giftcard_outlined),
                title: const Text("Package"), 
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.confirmation_number_outlined),
                title: const Text("Ticket"), 
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                title: const Text("Profile"),
              ),
            ],
          ),
        ),
      ),
      // Body sekarang dinamis berdasarkan indeks tab yang dipilih
      body: pages[_currentIndex],
    );
  }
}