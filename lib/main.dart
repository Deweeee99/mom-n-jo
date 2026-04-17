import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- IMPORT SEMUA SCREENS ---
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
import 'screens/subcategory_screen.dart';
import 'screens/booking_treatment_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/category_screen.dart';
import 'screens/member_status_screen.dart'; 
import 'screens/faq_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/termsofservice_screen.dart';
import 'screens/NotificationDetailScreen.dart';
import 'screens/list_notif_screen.dart';
import 'screens/upload_payment_screen.dart'; 
import 'screens/splash_screen.dart'; 
import 'screens/profile_selection_screen.dart'; // Screen pilih profil
import 'screens/add_profile_personal_screen.dart'; // Screen form personal details
import 'screens/add_profile_emergency_screen.dart'; // Screen form emergency contact
import 'screens/add_profile_medical_screen.dart'; // Screen form medical history

// ---> BRAY: Animasi FADE (Memudar) biar perpindahan halamannya 
// kelihatan super smooth dan elegan, serta nutupin lag render UI. <---
class SmoothFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, // Curve memudar yang paling smooth
        ),
      ),
      child: child,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomNJo App',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primaryColor: const Color(0xFF693D2C),
        // ---> BRAY: Terapin efek Smooth Fade ke semua platform <---
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SmoothFadePageTransitionsBuilder(),
            TargetPlatform.iOS: SmoothFadePageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/splash', 
      routes: {
        '/splash': (context) => const SplashScreen(), 
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/booking': (context) => const BookingScreen(),
        '/gift': (context) => const GiftScreen(),
        '/voucher': (context) => const VoucherScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/gerai_screen': (context) => const GeraiScreen(),
        '/produk_screen': (context) => const ProdukScreen(),
        '/history': (context) => const HistoryScreen(),
        '/tambah': (context) => const TambahScreen(),
        '/daftar': (context) => const DaftarScreen(),
        '/forget': (context) => const ForgetScreen(),
        '/editprofile': (context) => const EditProfileScreen(),
        '/FAQScreen': (context) => const FAQScreen(),
        '/ContactUsScreen': (context) => const ContactUsScreen(),
        '/TermsOfServiceScreen': (context) => const TermsOfServiceScreen(),
        '/NotificationDetailScreen': (context) => const NotificationDetailScreen(),
        '/ListNotifScreen': (context) => const ListNotifScreen(),
        '/member_status': (context) => const MemberStatusScreen(),
        
        // ---> BRAY: ROUTE BARU BUAT FITUR FAMILY PROFILE <---
        '/profile_selection': (context) => const ProfileSelectionScreen(),
        '/add_profile_personal': (context) => const AddProfilePersonalScreen(),
        
        '/UploadPaymen': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UploadPaymentScreen(idTransaksi: args['idTransaksi']);
        },

        '/subcategory': (context) {
          final route = ModalRoute.of(context);
          if (route == null) return const SubcategoryScreen(categoryId: 0);
          final rawArgs = route.settings.arguments;
          if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
            debugPrint("DEBUG: /subcategory dipanggil tanpa argumen");
            return const SubcategoryScreen(categoryId: 0);
          }
          final dynamic catIdValue = rawArgs['categoryId'];
          final int categoryId = catIdValue is int
              ? catIdValue
              : int.tryParse(catIdValue.toString()) ?? 0;
          final bookingData = rawArgs['bookingData'];
          debugPrint(
            "DEBUG: /subcategory => categoryId=$categoryId, bookingData=$bookingData",
          );
          return SubcategoryScreen(
            categoryId: categoryId,
            bookingData: bookingData,
          );
        },

        '/booking_treatment': (context) {
          final route = ModalRoute.of(context);
          if (route == null) {
            return const BookingTreatmentScreen(
              subcategoryId: 0,
              subcategoryName: 'Unknown',
            );
          }
          final rawArgs = route.settings.arguments;
          if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
            debugPrint("DEBUG: /booking_treatment dipanggil tanpa argumen");
            return const BookingTreatmentScreen(
              subcategoryId: 0,
              subcategoryName: 'Unknown',
            );
          }
          final dynamic subcatIdValue = rawArgs['subcategoryId'];
          final int subcategoryId = subcatIdValue is int
              ? subcatIdValue
              : int.tryParse(subcatIdValue.toString()) ?? 0;
          final subcatName = rawArgs['subcategoryName'] as String? ?? 'Unknown';
          
          final bookingData = rawArgs['bookingData']; 

          debugPrint(
            "DEBUG: /booking_treatment => subcategoryId=$subcategoryId, subcatName=$subcatName, bookingData=$bookingData",
          );
          return BookingTreatmentScreen(
            subcategoryId: subcategoryId,
            subcategoryName: subcatName,
            bookingData: bookingData, 
          );
        },

        '/booking_detail': (context) {
          final route = ModalRoute.of(context);
          if (route == null) return BookingDetailScreen(bookingData: const {});
          final rawArgs = route.settings.arguments;
          if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
            debugPrint("DEBUG: /booking_detail dipanggil tanpa argumen");
            return BookingDetailScreen(bookingData: const {});
          }
          debugPrint("DEBUG: /booking_detail, args: $rawArgs");
          return BookingDetailScreen(bookingData: rawArgs);
        },

        '/kategori': (context) {
          final route = ModalRoute.of(context);
          final rawArgs = route?.settings.arguments;
          if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
            return const CategoryScreen();
          }
          debugPrint("DEBUG: /kategori, args: $rawArgs");
          return CategoryScreen(bookingData: rawArgs);
        },

        // ---> BRAY: Route buat passing data dari layar ke layar pas bikin profil <---
        '/add_profile_emergency': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AddProfileEmergencyScreen(personalData: args);
        },

        '/add_profile_medical': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AddProfileMedicalScreen(previousData: args);
        },
      },
    );
  }
}