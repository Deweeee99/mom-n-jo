import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Ambil identitas (rekening, whatsapp, email, nama_website, no_telp)
  Future<void> _fetchIdentitas() async {
    final url = Uri.parse('https://app.momnjo.com/api/get_identitas.php');
    try {
      debugPrint('[HistoryScreen] fetching identitas');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      debugPrint(
          '[HistoryScreen] get_identitas status: ${response.statusCode}');
      debugPrint('[HistoryScreen] get_identitas body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['status'] == 'success' &&
            decoded['data'] is Map<String, dynamic>) {
          setState(() {
            _identitasData = Map<String, dynamic>.from(
                decoded['data'] as Map<String, dynamic>);
          });
        } else {
          debugPrint('[HistoryScreen] get_identitas unexpected format');
        }
      } else {
        debugPrint(
            '[HistoryScreen] get_identitas non-200: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[HistoryScreen] Exception fetchIdentitas: $e');
    }
  }

  // Pop up info "kirim bukti kemana" untuk booking yang sedang diproses
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
        title: const Text("Informasi Pembayaran"),
        content: SingleChildScrollView(
          child: Text(pesan),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Auto-expire: jika waktu sudah habis, update status menjadi "Deleted"
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
        debugPrint("Booking $idTransaksi expired and updated.");
      } else {
        debugPrint(
          'Failed to auto-expire booking. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error auto-expire booking: $e');
    }
  }

  Widget _buildTransaksiCard(Map<String, dynamic> trx) {
    final String statusRaw = (trx['status'] ?? '').toString().toLowerCase();

    // Parsing waktu booking (tgl_dokumen + jam)
    DateTime bookingStart;
    try {
      bookingStart = DateTime.parse("${trx['tgl_dokumen']} ${trx['jam']}");
    } catch (e) {
      bookingStart = DateTime.now();
    }

    // Parsing deadline; fallback: bookingStart + 15 menit.
    DateTime deadline;
    try {
      deadline = parseServerTime(trx['batas_waktu']);
    } catch (e) {
      deadline = bookingStart.add(const Duration(minutes: 15));
    }

    DateTime now = DateTime.now();
    Duration timeLeft = deadline.difference(now);
    bool isExpired = now.isAfter(deadline);

    // Auto-expire
    if (timeLeft.inSeconds <= 0 &&
        !_expiredTransactions.contains(trx['id_transaksi'].toString()) &&
        statusRaw != "deleted" &&
        statusRaw != "delete") {
      _expiredTransactions.add(trx['id_transaksi'].toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoExpireBooking(trx);
      });
    }

    // Countdown hanya untuk status "acc"
    bool showCountdown = false;
    String countdownLabel = "";
    if (statusRaw == "acc" && timeLeft.inSeconds > 0 && !isExpired) {
      showCountdown = true;
      countdownLabel = "Waktu berjalan:";
    }

    // Keterangan tambahan berdasarkan status
    Widget additionalInfo;
    if (statusRaw == "acc") {
      additionalInfo = const Text(
        'Mohon Melakukan Pembayaran DP Sebesar IDR 100.000 Sebelum Waktu Habis',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      );
    } else if (statusRaw == "open") {
      additionalInfo = const Text(
        'Silakan kunjungi gerai yang dituju sesuai pemesanan anda',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      );
    } else if (statusRaw == "deleted" || statusRaw == "delete") {
      additionalInfo = const Text(
        'Booking Sudah expired',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    } else if (statusRaw == "booking") {
      additionalInfo = const Text(
        'Booking menunggu ACC dari admin',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      );
    } else {
      additionalInfo = const SizedBox.shrink();
    }

    // Card bisa di-tap:
    // - status "acc": ke upload pembayaran
    // - status "booking": popup info rekening + WA
    final bool isClickable = (statusRaw == "acc" || statusRaw == "booking");

    // warna kartu
    Color cardColor;
    if (isExpired) {
      cardColor = Colors.grey.shade300;
    } else if (statusRaw == "open") {
      cardColor = Colors.orangeAccent.withOpacity(0.3);
    } else if (statusRaw == "acc") {
      cardColor = Colors.greenAccent.withOpacity(0.3);
    } else {
      cardColor = Colors.white;
    }

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: cardColor,
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.brown),
        title: Text('Transaksi #${trx['id_transaksi']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tgl Dokumen: ${trx['tgl_dokumen']}'),
            Text('Jam: ${trx['jam']}'),
            Text('Terapis: ${trx['id_terapis']}'),
            Text('Deskripsi: ${trx['deskripsi']}'),
            Text('Status: ${trx['status']}'),
            additionalInfo,
            Text('Customer: ${trx['customer']}'),
            if (showCountdown)
              Text(
                '$countdownLabel '
                '${timeLeft.inMinutes.remainder(60).toString().padLeft(2, "0")} : '
                '${timeLeft.inSeconds.remainder(60).toString().padLeft(2, "0")}',
                style: const TextStyle(color: Colors.red),
              ),
            if (isExpired)
              const Text(
                'Booking expired',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: isClickable
            ? () {
                if (statusRaw == "acc") {
                  // status acc -> ke upload bukti pembayaran
                  Navigator.pushNamed(
                    context,
                    '/UploadPaymen',
                    arguments: {'idTransaksi': trx['id_transaksi']},
                  );
                } else if (statusRaw == "booking") {
                  // status booking -> pop up info rekening + WA
                  _showBookingInfoDialog();
                }
              }
            : null,
      ),
    );

    // Swipe-to-delete hanya untuk status "booking" yang belum expired
    if ((statusRaw == "booking") && !isExpired) {
      return Dismissible(
        key: Key(trx['id_transaksi'].toString()),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Batalkan Booking'),
              content: const Text(
                'Apakah anda yakin untuk membatalkan booking ini?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Ya'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          try {
            final cancelUrl = Uri.parse(
              'https://app.momnjo.com/api/cancel_booking.php',
            );
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
                  (item) =>
                      item['id_transaksi'].toString() == trx['id_transaksi'],
                );
                if (index != -1) {
                  _listTransaksi[index]['status'] = 'Deleted';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking dibatalkan.')),
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
        },
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('History Booking')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Anda belum login.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login Dulu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History Booking')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _listTransaksi.isEmpty
            ? const Center(child: Text('Data transaksi kosong.'))
            : ListView.builder(
                itemCount: _listTransaksi.length,
                itemBuilder: (context, index) {
                  final item = _listTransaksi[index];
                  return _buildTransaksiCard(item);
                },
              ),
      ),
    );
  }
}
