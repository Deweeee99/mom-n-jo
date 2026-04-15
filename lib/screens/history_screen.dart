import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Fungsi parseServerTime: asumsikan API mengirimkan string waktu dengan format "YYYY-MM-DD HH:mm:ss"
DateTime parseServerTime(String timeString) {
  return DateTime.parse(timeString);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _idCustomer = '';
  List<dynamic> _listTransaksi = [];

  // untuk auto-expire
  Timer? _timer;
  final Set<String> _expiredTransactions = {};

  // identitas (rekening, whatsapp, email, nama_website, no_telp)
  Map<String, dynamic>? _identitasData;

  // Tema Warna Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _btnColor = const Color(0xFFDBA38C); // Warna Peach Tombol

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
    _fetchIdentitas(); // ambil rekening + WA dari API

    // Update setiap detik untuk countdown real-time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginAndFetch() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String idCustomer = prefs.getString('id_customer') ?? '';

    if (!loggedIn || idCustomer.isEmpty) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoggedIn = true;
      _idCustomer = idCustomer;
    });
    await _fetchTransaksi(idCustomer);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchTransaksi(String customerId) async {
    try {
      final url = Uri.parse(
        'https://app.momnjo.com/api/get_history.php?id_customer=$customerId',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _listTransaksi = data;
        });
      } else {
        debugPrint('Failed to load data. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  Future<void> _fetchIdentitas() async {
    final url = Uri.parse('https://app.momnjo.com/api/get_identitas.php');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['status'] == 'success' &&
            decoded['data'] is Map<String, dynamic>) {
          setState(() {
            _identitasData = Map<String, dynamic>.from(
                decoded['data'] as Map<String, dynamic>);
          });
        }
      }
    } catch (e) {
      debugPrint('[HistoryScreen] Exception fetchIdentitas: $e');
    }
  }

  void _showBookingInfoDialog() {
    final namaSpa =
        _identitasData?['nama_website']?.toString().trim().isNotEmpty == true
            ? _identitasData!['nama_website'].toString()
            : 'Mom N Jo';

    final rekening =
        _identitasData?['rekening']?.toString().trim().isNotEmpty == true
            ? _identitasData!['rekening'].toString()
            : '[metode pembayaran]';

    final wa = _identitasData?['whatsapp']?.toString().trim().isNotEmpty == true
        ? _identitasData!['whatsapp'].toString()
        : '';

    final email = _identitasData?['email']?.toString().trim().isNotEmpty == true
        ? _identitasData!['email'].toString()
        : '';

    final noTelp =
        _identitasData?['no_telp']?.toString().trim().isNotEmpty == true
            ? _identitasData!['no_telp'].toString()
            : '';

    String kontakKonfirmasi;
    if (wa.isNotEmpty && email.isNotEmpty) {
      kontakKonfirmasi = 'WhatsApp $wa atau email $email';
    } else if (wa.isNotEmpty) {
      kontakKonfirmasi = 'WhatsApp $wa';
    } else if (email.isNotEmpty) {
      kontakKonfirmasi = 'email $email';
    } else if (noTelp.isNotEmpty) {
      kontakKonfirmasi = 'Telp $noTelp';
    } else {
      kontakKonfirmasi = '[nomor WhatsApp/email]';
    }

    final pesan = """
Terima kasih telah melakukan pemesanan treatment di $namaSpa!

Agar booking Anda dapat dikonfirmasi dan slot waktu tetap tersedia, mohon segera lakukan pembayaran booking fee sebesar IDR 100.000 ke:
$rekening

Setelah pembayaran dilakukan, silakan kirim bukti transfer ke $kontakKonfirmasi. Setelah di-ACC oleh admin, jika dalam 2 jam belum ada pembayaran, booking akan dibatalkan secara otomatis.

Terima kasih, kami tunggu konfirmasi Anda!

$namaSpa
$noTelp
""";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Informasi Pembayaran", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(pesan, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup', style: TextStyle(color: _btnColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _autoExpireBooking(Map<String, dynamic> trx) async {
    final String idTransaksi = trx['id_transaksi'].toString();
    final url = Uri.parse('https://app.momnjo.com/api/auto_expire_booking.php');
    try {
      final response = await http.post(
        url,
        body: {'id_transaksi': idTransaksi, 'id_customer': _idCustomer},
      );
      if (response.statusCode == 200) {
        setState(() {
          final int index = _listTransaksi.indexWhere(
            (item) => item['id_transaksi'].toString() == idTransaksi,
          );
          if (index != -1) {
            _listTransaksi[index]['status'] = 'Deleted';
          }
        });
      }
    } catch (e) {
      debugPrint('Error auto-expire booking: $e');
    }
  }

  // FUNGSI CANCEL BOOKING YANG BARU DIJADIKAN TOMBOL
  Future<void> _cancelBooking(Map<String, dynamic> trx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Booking', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah anda yakin untuk membatalkan booking ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final cancelUrl = Uri.parse('https://app.momnjo.com/api/cancel_booking.php');
        final response = await http.post(
          cancelUrl,
          body: {
            'id_transaksi': trx['id_transaksi'].toString(),
            'id_customer': _idCustomer,
          },
        );
        if (response.statusCode == 200) {
          setState(() {
            final int index = _listTransaksi.indexWhere(
              (item) => item['id_transaksi'].toString() == trx['id_transaksi'],
            );
            if (index != -1) {
              _listTransaksi[index]['status'] = 'Deleted';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking berhasil dibatalkan.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membatalkan booking.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error membatalkan booking.')),
        );
      }
    }
  }

  Widget _buildTransaksiCard(Map<String, dynamic> trx) {
    final String statusRaw = (trx['status'] ?? '').toString().toLowerCase();

    DateTime bookingStart;
    try {
      bookingStart = DateTime.parse("${trx['tgl_dokumen']} ${trx['jam']}");
    } catch (e) {
      bookingStart = DateTime.now();
    }

    DateTime deadline;
    try {
      deadline = parseServerTime(trx['batas_waktu']);
    } catch (e) {
      deadline = bookingStart.add(const Duration(minutes: 15));
    }

    DateTime now = DateTime.now();
    Duration timeLeft = deadline.difference(now);
    bool isExpired = now.isAfter(deadline);

    if (timeLeft.inSeconds <= 0 &&
        !_expiredTransactions.contains(trx['id_transaksi'].toString()) &&
        statusRaw != "deleted" &&
        statusRaw != "delete") {
      _expiredTransactions.add(trx['id_transaksi'].toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoExpireBooking(trx);
      });
    }

    // Format Tanggal dan Jam
    String formattedDate = DateFormat('dd MMM yyyy').format(bookingStart);
    String timeStr = trx['jam'] != null ? trx['jam'].toString().substring(0, 5) : '';

    // SETUP STATUS BADGE & INFO TEXT
    Color badgeBgColor = Colors.grey.shade200;
    Color badgeTextColor = Colors.grey.shade700;
    String badgeText = "UNKNOWN";
    String infoText = "";
    Color infoColor = Colors.black87;

    bool showCountdown = false;

    if (statusRaw == "booking") {
      badgeBgColor = const Color(0xFFFDECDA); // Light orange/peach
      badgeTextColor = const Color(0xFFD68A59); // Orange text
      badgeText = "PENDING";
      infoText = "Waiting for branch confirmation";
      infoColor = const Color(0xFFB57C4A);
    } else if (statusRaw == "acc") {
      badgeBgColor = Colors.blue.shade50;
      badgeTextColor = Colors.blue.shade700;
      badgeText = "WAITING PAYMENT";
      infoText = "Please pay DP IDR 100.000";
      infoColor = Colors.blue.shade700;
      if (!isExpired) showCountdown = true;
    } else if (statusRaw == "open") {
      badgeBgColor = Colors.green.shade50;
      badgeTextColor = Colors.green.shade700;
      badgeText = "CONFIRMED";
      infoText = "Your booking is confirmed";
      infoColor = Colors.green.shade700;
    } else if (statusRaw == "deleted" || statusRaw == "delete") {
      badgeBgColor = Colors.red.shade50;
      badgeTextColor = Colors.red.shade700;
      badgeText = "CANCELLED";
      infoText = "Booking has been expired / cancelled";
      infoColor = Colors.red.shade700;
    }

    // Logic Countdown
    if (showCountdown) {
      String m = timeLeft.inMinutes.remainder(60).toString().padLeft(2, "0");
      String s = timeLeft.inSeconds.remainder(60).toString().padLeft(2, "0");
      infoText += " ($m:$s)";
    }
    if (isExpired && statusRaw == "acc") {
      badgeBgColor = Colors.red.shade50;
      badgeTextColor = Colors.red.shade700;
      badgeText = "EXPIRED";
      infoText = "Payment time has expired";
      infoColor = Colors.red.shade700;
    }

    // Logic Button Clickable
    final bool showViewDetail = (statusRaw == "acc" || statusRaw == "booking");
    final bool showCancelButton = (statusRaw == "booking" && !isExpired);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris 1: ID Transaksi & Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // BRAY: INI DIA FIX-NYA! Pake Expanded & Flexible biar teks ga bablas
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'TRANSACTION : ${trx['id_transaksi']}', // Dummy prefix TRX26 biar mirip mockup
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Kalo mentok jadi titik-titik
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.auto_awesome, color: Color(0xFFDBA38C), size: 16),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 2: Jam & Terapis
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 24),
              Icon(Icons.person_outline, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trx['id_terapis']?.toString().isNotEmpty == true ? trx['id_terapis'] : 'Any Therapist',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 3: Badge Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeTextColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Baris 4: Info Status
          Text(
            infoText,
            style: TextStyle(
              fontSize: 13,
              color: infoColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Baris 5: Nama Treatment & Customer ID
          Text(
            trx['deskripsi']?.toString().isNotEmpty == true ? trx['deskripsi'] : 'Detail Treatment',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            trx['customer'] ?? '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          
          const SizedBox(height: 20),

          // Baris 6: Tombol Aksi (Cancel & View Detail)
          if (showCancelButton || showViewDetail)
            Row(
              children: [
                if (showCancelButton)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _btnColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () => _cancelBooking(trx),
                      child: Text(
                        'Cancel Booking', // Diubah jadi Cancel Booking sesuai instruksi
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  
                if (showCancelButton && showViewDetail) const SizedBox(width: 12),
                
                if (showViewDetail)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _btnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () {
                        if (statusRaw == "acc") {
                          Navigator.pushNamed(
                            context,
                            '/UploadPaymen',
                            arguments: {'idTransaksi': trx['id_transaksi']},
                          );
                        } else if (statusRaw == "booking") {
                          _showBookingInfoDialog();
                        }
                      },
                      child: Text(
                        statusRaw == 'acc' ? 'Upload Payment' : 'View Detail',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFFEAD8C0),
          elevation: 2,
          shadowColor: Colors.black26,
          centerTitle: true,
          title: Text(
            'History Booking',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_rounded, size: 80, color: _primaryColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Anda belum login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna solid krim
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        title: Text(
          'History Booking',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          // Background Tipis
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bookbg.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          SafeArea(
            child: _listTransaksi.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: _primaryColor.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Data transaksi kosong.',
                          style: TextStyle(fontSize: 16, color: _primaryColor.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: _listTransaksi.length,
                    itemBuilder: (context, index) {
                      final item = _listTransaksi[index];
                      return _buildTransaksiCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}