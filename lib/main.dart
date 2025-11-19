import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/gift_screen.dart';
import 'screens/voucher_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/gerai_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/history_screen.dart';
import 'screens/tambah_screen.dart';
import 'screens/daftar_screen.dart';
import 'screens/forget_screen.dart';
import 'screens/editprofile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mengunci orientasi ke portraitUp saja
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomNJo App',
      theme: ThemeData(
        primaryColor: const Color(0xFF693D2C),
        // ... pengaturan tema lainnya
      ),
      initialRoute: '/home',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking': (context) => const BookingScreen(),
        '/gift': (context) => const GiftScreen(),
        '/voucher': (context) => const VoucherScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/gerai_screen': (context) => const GeraiScreen(), // Halaman Gerai
        '/History': (context) => const HistoryScreen(), // Halaman History
        '/Tambah': (context) => const TambahScreen(), // Halaman Tambah
        '/produk_screen': (context) => const ProdukScreen(), // Halaman Produk
        '/daftar': (context) => const DaftarScreen(), // Halaman Daftar
        '/editprofile': (context) => const EditProfileScreen(),
      },
    );
  }
}
