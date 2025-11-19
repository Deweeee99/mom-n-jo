import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TambahScreen extends StatefulWidget {
  const TambahScreen({super.key});

  @override
  State<TambahScreen> createState() => _TambahScreenState();
}

class _TambahScreenState extends State<TambahScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kolom form
  DateTime? _selectedDate; // tgl_dokumen
  TimeOfDay? _selectedTime; // jam
  final TextEditingController _remarkController = TextEditingController();

  // Data user (login)
  bool _isLoggedIn = false;
  String? _idCustomer;
  String? _fullname; // jika ingin ditampilkan di UI

  // Batas jam
  final int startHour = 8;
  final int endHour = 16;

  @override
  void initState() {
    super.initState();
    _loadLoginData();
  }

  /// Muat data login (id_customer, fullname) dari SharedPreferences
  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final customerId = prefs.getString('id_customer');
    final name = prefs.getString('fullname');
    setState(() {
      _isLoggedIn = loggedIn;
      _idCustomer = customerId;
      _fullname = name;
    });
  }

  /// Pilih Tanggal
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Pilih Jam (08:00 sampai 16:00)
  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null) {
      // Pastikan jamnya di antara 08 s/d 16
      if (picked.hour < startHour || picked.hour > endHour) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jam harus antara $startHour:00 dan $endHour:00'),
          ),
        );
      } else {
        setState(() {
          _selectedTime = picked;
        });
      }
    }
  }

  /// Simpan data ke server
  Future<void> _submitData() async {
    if (!_isLoggedIn || _idCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login!')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan jam!')),
      );
      return;
    }

    // Format date => yyyy-MM-dd
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    // Format time => HH:mm:ss
    final hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute:00';

    final remark = _remarkController.text.trim();

    try {
      final url = Uri.parse('https://app.momnjo.com/api/tambah_transaksi.php');
      final response = await http.post(url, body: {
        'tgl_dokumen': dateString,
        'jam': timeString,
        'deskripsi': remark,
        'customer': _idCustomer, // id_customer login
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil disimpan! ID Transaksi: ${result['id_transaksi']}',
              ),
            ),
          );
          Navigator.pop(context); // kembali/tutup form
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  /// Konten form booking
  Widget _buildFormContent() {
    final dateDisplay = _selectedDate == null
        ? 'Pilih Tanggal'
        : DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final timeDisplay = _selectedTime == null
        ? 'Pilih Jam'
        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nama Pelanggan (read-only)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan',
                  prefixIcon: Icon(Icons.person),
                ),
                readOnly: true,
                initialValue: _fullname ?? 'No Name',
              ),
              const SizedBox(height: 16),

              // ID Customer (read-only)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'ID Customer',
                  prefixIcon: Icon(Icons.numbers),
                ),
                readOnly: true,
                initialValue: _idCustomer ?? '',
              ),
              const SizedBox(height: 16),

              // Pilih Tanggal
              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Booking',
                    prefixIcon: const Icon(Icons.date_range),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(dateDisplay),
                ),
              ),
              const SizedBox(height: 16),

              // Pilih Jam
              InkWell(
                onTap: () => _pickTime(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Jam Booking',
                    prefixIcon: const Icon(Icons.access_time_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(timeDisplay),
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: 'Catatan / Keterangan',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Tombol Submit (warna pastel, lebih lembut)
              ElevatedButton.icon(
                onPressed: _submitData,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Booking'),
                style: ElevatedButton.styleFrom(
                  // Warna pastel yang lebih lembut
                  backgroundColor: const Color(0xFFFFB5C2),
                  foregroundColor: Colors.white, // teks menjadi putih
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan jika user belum login
  Widget _buildNotLoggedInView() {
    return Center(
      child: Text(
        'Anda belum login!',
        style: TextStyle(
          fontSize: 18,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Agar latar gradien penuh hingga di balik AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Input Booking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // Latar belakang pastel lembut (gradient)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE3EC), // Pastel pink muda
              Color(0xFFFFF5F7), // Putih mendekati pink
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  _isLoggedIn ? _buildFormContent() : _buildNotLoggedInView(),
            ),
          ),
        ),
      ),
    );
  }
}
