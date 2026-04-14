// lib/screens/profile_screen.dart
// Revised complete ProfileScreen matching the new mockup UI
// - auto-logout on reload/background (debounced)
// - controllers as state members to avoid use-after-dispose
// - all async UI ops guarded by mounted checks
// - safe Navigator usage via SchedulerBinding.addPostFrameCallback
// - robust HTTP status handling
//
// Required packages in pubspec.yaml:
//   http, shared_preferences, salomon_bottom_bar, url_launcher

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  String _fullname = '';
  String _idCustomer = '';

  // API endpoints - sesuaikan bila perlu
  final String deleteApiUrl = 'https://app.momnjo.com/api/delete_account.php';
  final String changePassApiUrl = 'https://app.momnjo.com/api/change_password.php';

  // Controllers sebagai member state (menghindari race/dispose issues)
  final TextEditingController _pwCtrl = TextEditingController();
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confPassCtrl = TextEditingController();

  Timer? _autoLogoutTimer; // debounce timer for auto logout

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLogoutTimer?.cancel();
    try { _pwCtrl.dispose(); } catch (_) {}
    try { _oldPassCtrl.dispose(); } catch (_) {}
    try { _newPassCtrl.dispose(); } catch (_) {}
    try { _confPassCtrl.dispose(); } catch (_) {}
    super.dispose();
  }

  // Hot-reload (debug) => force logout to keep state clean during development
  @override
  void reassemble() {
    super.reassemble();
    _forceLogoutOnReload();
  }

  // Lifecycle handler: schedule auto-logout on background/inactive/detached (debounced)
  @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.inactive ||
  //       state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.detached) {
  //     _autoLogoutTimer?.cancel();
  //     _autoLogoutTimer = Timer(const Duration(seconds: 1), () {
  //       _forceLogoutOnReload();
  //     });
  //   } else if (state == AppLifecycleState.resumed) {
  //     _autoLogoutTimer?.cancel();
  //   }
  // }

  Future<void> _forceLogoutOnReload() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!loggedIn) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoggedIn = true;
    });
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullname = prefs.getString('fullname') ?? 'No Name';
      _idCustomer = prefs.getString('id_customer') ?? 'Unknown';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      });
    }
  }

  // Desain menu list disesuaikan dengan mockup (tanpa border bawah, padding luas)
  Widget _buildProfileItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 22),
          ],
        ),
      ),
    );
  }

  // ------------------ Delete account (password required) ------------------
  Future<void> _confirmAndDeleteWithPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final idCustomer = prefs.getString('id_customer') ?? _idCustomer;

    _pwCtrl.text = '';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus Akun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan password Anda untuk mengonfirmasi penghapusan akun. Data pribadi akan dianonimkan dan riwayat transaksi tetap disimpan.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Batal')),
            TextButton(
              onPressed: () {
                if (_pwCtrl.text.trim().isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak boleh kosong')));
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    final password = _pwCtrl.text.trim();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse(deleteApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id_customer': idCustomer,
          'password': password,
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          final prefs2 = await SharedPreferences.getInstance();
          await prefs2.clear();
          if (!mounted) return;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Akun berhasil dihapus')));
            Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
          });
        } else {
          final msg = body['message'] ?? 'Gagal menghapus akun';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else if (response.statusCode == 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak sesuai. Mohon coba lagi.')));
      } else if (response.statusCode == 403) {
        String msg = 'Akses ditolak (403)';
        try {
          final b = json.decode(response.body);
          if (b['message'] != null) msg = b['message'];
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else if (response.statusCode >= 500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan pada server, silakan coba lagi nanti.')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      try { Navigator.of(context).pop(); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ------------------ Change password (old + new) ------------------
  Future<void> _showChangePasswordDialog() async {
    _oldPassCtrl.text = '';
    _newPassCtrl.text = '';
    _confPassCtrl.text = '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isProcessing = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ganti Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password lama'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password baru'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Konfirmasi password baru'),
                ),
                const SizedBox(height: 8),
                const Text('Minimal 6 karakter.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final oldP = _oldPassCtrl.text.trim();
                        final newP = _newPassCtrl.text.trim();
                        final confP = _confPassCtrl.text.trim();

                        if (oldP.isEmpty || newP.isEmpty || confP.isEmpty) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua field')));
                          return;
                        }
                        if (newP.length < 6) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru minimal 6 karakter')));
                          return;
                        }
                        if (newP != confP) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
                          return;
                        }

                        setState(() => isProcessing = true);
                        final ok = await _performChangePassword(oldP, newP);
                        setState(() => isProcessing = false);
                        if (ok == true) {
                          if (!mounted) return;
                          Navigator.pop(dialogCtx, true);
                        }
                      },
                child: const Text('Ubah', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool?> _performChangePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final idCustomer = prefs.getString('id_customer') ?? _idCustomer;
    if (idCustomer.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User tidak ditemukan')));
      return false;
    }

    if (!mounted) return false;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final response = await http.post(
        Uri.parse(changePassApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'id_customer': idCustomer,
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return false;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          if (!mounted) return true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Password berhasil diubah')));
          return true;
        } else {
          final msg = body['message'] ?? 'Gagal mengubah password';
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          return false;
        }
      } else if (response.statusCode == 401) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password lama tidak sesuai')));
        return false;
      } else if (response.statusCode == 400) {
        String msg = 'Permintaan tidak valid';
        try {
          final Map<String, dynamic> b = json.decode(response.body);
          if (b['message'] != null) msg = b['message'];
        } catch (_) {}
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return false;
      } else {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      try { Navigator.of(context).pop(); } catch (_) {}
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Latar belakang putih bersih
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.black),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profil
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE8E0FF), // Warna ungu muda dari mockup
            ),
            const SizedBox(height: 16),
            Text(
              _fullname,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5A3D31)),
            ),
            const SizedBox(height: 4),
            Text(
              _idCustomer,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Navigasi ke Halaman Member Status (Mockup 2)
                Navigator.pushNamed(context, '/member_status');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC7B5), // Warna gold muda
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Member Gold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),

            // Kartu Riwayat Transaksi
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF693D2C)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Rp 0',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFDCC7B5)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belanja dan kumpulkan poin untuk naik ke level selanjutnya!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daftar Menu
            _buildProfileItem('Edit Profile', onTap: () => Navigator.pushNamed(context, '/editprofile')),
            _buildProfileItem('Ganti Password', onTap: () => _showChangePasswordDialog()),
            _buildProfileItem('Promo', onTap: () => _launchURL("https://www.momnjo.com/promo")),
            _buildProfileItem('MPC Member Area', onTap: () => _launchURL("https://www.momnjo.com/mpc")),
            _buildProfileItem('Contact Us & Suggestion', onTap: () => Navigator.pushNamed(context, '/ContactUsScreen')),
            _buildProfileItem('Rate', onTap: () {}), // Ditambahkan sesuai Mockup
            _buildProfileItem('Terms of Service', onTap: () => Navigator.pushNamed(context, '/TermsOfServiceScreen')),
            _buildProfileItem('FAQ', onTap: () => Navigator.pushNamed(context, '/FAQScreen')),

            const SizedBox(height: 32),

            // Tombol Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Hapus Akun (Ditampilkan dengan desain bersih)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: TextButton(
                onPressed: _confirmAndDeleteWithPassword,
                child: const Text('Hapus Akun', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar telah DIHAPUS dari sini untuk menghindari duplikasi
      // dengan navbar yang ada di parent screen.
    );
  }
}