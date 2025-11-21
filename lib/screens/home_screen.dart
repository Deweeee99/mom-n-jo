import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Fungsi navigasi dengan loading
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
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 71, 60, 60),
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
  int _notifCount = 0; // jumlah notifikasi

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

  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        navigateWithLoading(context, '/booking');
        break;
      case 2:
        navigateWithLoading(context, '/gift');
        break;

      case 3:
        navigateWithLoading(context, '/voucher');
        break;
      case 4:
        navigateWithLoading(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
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
            SalomonBottomBarItem(
                icon: const Icon(Icons.home),
                title: const Text("Home"),
                selectedColor: const Color(0xFF693D2C)),
            SalomonBottomBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                title: const Text("Booking"),
                selectedColor: const Color(0xFF693D2C)),
            SalomonBottomBarItem(
                icon: const Icon(Icons.card_giftcard_outlined),
                title: const Text("Gift"),
                selectedColor: const Color(0xFF693D2C)),
            // Gift
            SalomonBottomBarItem(
                icon: const Icon(Icons.confirmation_number_outlined),
                title: const Text("Voucher"),
                selectedColor: const Color(0xFF693D2C)),
            SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                title: const Text("Profile"),
                selectedColor: const Color(0xFF693D2C)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    bottomRight: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/momnjo_logo.png', height: 60),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/ListNotifScreen');
                              },
                            ),
                            if (_notifCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$_notifCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isLoggedIn ? 'Hi, $_fullname!' : 'Hi, Mom!',
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            const Text('How can we help you today?',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: CarouselSlider(
                    items: banners
                        .map((banner) => Image.asset(banner,
                            width: double.infinity, fit: BoxFit.cover))
                        .toList(),
                    options: CarouselOptions(
                        height: 220,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        enlargeCenterPage: false,
                        aspectRatio: 16 / 9,
                        viewportFraction: 1.0),
                  ),
                ),
              ),
            ),
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
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Image.asset('assets/promo.png',
                      width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SizedBox(
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/txt-branches.png',
                      width: 190,
                      height: 70,
                      alignment: Alignment.center,
                      fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _branches.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF693D2C)))
                  : CarouselSlider.builder(
                      itemCount: _branches.length,
                      itemBuilder:
                          (BuildContext context, int index, int realIndex) {
                        final branch = _branches[index];
                        int branchId = int.tryParse(branch.id) ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              navigateWithLoading(context, '/gerai_screen',
                                  arguments: branchId);
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12)),
                                    child: Image.asset('assets/darmawangsa.png',
                                        fit: BoxFit.cover, height: 110),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(branch.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF693D2C))),
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
                          scrollPhysics: const BouncingScrollPhysics()),
                    ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SizedBox(
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/txt-recommended-service.png',
                      width: 250,
                      height: 70,
                      alignment: Alignment.center,
                      fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _categories.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF693D2C)))
                  : GridView.builder(
                      itemCount: _categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final category = _categories[index];
                        final baseUrl =
                            'https://app.momnjo.com/assets/foto_kategori/';
                        final fullImageUrl = '$baseUrl${category.image}';
                        return GestureDetector(
                          onTap: () {
                            final categoryId =
                                int.tryParse(category.id.toString()) ?? 0;
                            navigateWithLoading(context, '/subcategory',
                                arguments: {
                                  'categoryId': categoryId,
                                  'bookingData': null,
                                });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12)),
                                  child: Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                    height: 130,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 130,
                                        color: Colors.grey[300],
                                        child:
                                            const Icon(Icons.image, size: 50),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(category.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF693D2C)),
                                      textAlign: TextAlign.center),
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
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Image.asset('assets/home-service.png',
                      width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
