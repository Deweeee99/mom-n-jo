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

  Timer? _timer;
  final Set<String> _expiredTransactions = {};

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
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

    // Jika waktu sudah habis dan status belum "deleted", auto-expire (sekali saja)
    if (timeLeft.inSeconds <= 0 &&
        !_expiredTransactions.contains(trx['id_transaksi'].toString()) &&
        statusRaw != "deleted" &&
        statusRaw != "delete") {
      _expiredTransactions.add(trx['id_transaksi'].toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoExpireBooking(trx);
      });
    }

    // Countdown hanya untuk status "acc" (jika waktu tersisa > 0 dan belum expired)
    bool showCountdown = false;
    String countdownLabel = "";
    if (statusRaw == "acc" && timeLeft.inSeconds > 0 && !isExpired) {
      showCountdown = true;
      countdownLabel = "Waktu berjalan:";
    }

    // Tentukan keterangan tambahan berdasarkan status
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
    } else {
      additionalInfo = const Text(
        'History Booking terdahulu',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      );
    }

    // Tentukan apakah card dapat di-tap:
    // - Hanya jika status adalah "acc", card dapat di-tap ke halaman upload pembayaran.
    bool isClickable = (statusRaw == "acc");

    // Atur warna kartu:
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
                '$countdownLabel ${timeLeft.inMinutes.remainder(60).toString().padLeft(2, "0")} : ${timeLeft.inSeconds.remainder(60).toString().padLeft(2, "0")}',
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
                // Jika status acc, card dapat di-tap untuk ke halaman upload pembayaran.
                Navigator.pushNamed(
                  context,
                  '/UploadPaymen',
                  arguments: {'idTransaksi': trx['id_transaksi']},
                );
              }
            : null,
      ),
    );

    // Jika status masih "booking" dan belum expired, izinkan swipe untuk membatalkan.
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
