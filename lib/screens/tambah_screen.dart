// tambah_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TambahScreen extends StatefulWidget {
  const TambahScreen({super.key});

  @override
  State<TambahScreen> createState() => _TambahScreenState();
}

class _TambahScreenState extends State<TambahScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers & state
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();

  // Dropdown data
  List<dynamic> _geraiList = [];
  String? _selectedGerai;

  List<dynamic> _terapisList = [];
  String? _selectedTerapis;

  // User
  bool _isLoggedIn = false;
  String? _idCustomer;
  String? _fullname;

  // ensure arguments processed only once
  bool _argsProcessed = false;

  // Time slots
  final List<String> _timeSlots = [
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "12:00",
    "12:30",
    "13:00",
    "13:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
    "16:00",
    "16:30",
    "17:00",
  ];

  @override
  void initState() {
    super.initState();
    _loadLoginData(); // load prefs, may set _idCustomer and trigger fetchCustomerMobile
    _fetchGerai();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsProcessed) {
      final argsRaw = ModalRoute.of(context)?.settings.arguments;
      Map<String, dynamic>? argsMap;

      // tolerate wrapped bookingData or direct map
      if (argsRaw is Map<String, dynamic>) {
        if (argsRaw.containsKey('bookingData') &&
            argsRaw['bookingData'] is Map<String, dynamic>) {
          argsMap = Map<String, dynamic>.from(argsRaw['bookingData']);
        } else {
          argsMap = Map<String, dynamic>.from(argsRaw);
        }
      } else if (argsRaw != null) {
        try {
          argsMap = Map<String, dynamic>.from(argsRaw as Map);
        } catch (_) {
          argsMap = null;
        }
      }

      debugPrint('[TambahScreen] ModalRoute.arguments raw: $argsRaw');
      debugPrint('[TambahScreen] parsed argsMap: $argsMap');

      if (argsMap != null) {
        final idCustomer = argsMap['id_customer'] ??
            argsMap['idCustomer'] ??
            argsMap['customer'];
        final fullname =
            argsMap['fullname'] ?? argsMap['full_name'] ?? argsMap['name'];
        final gerai =
            argsMap['gerai'] ?? argsMap['kode_gerai'] ?? argsMap['kodeGerai'];
        final mobileFromArgs =
            argsMap['mobile_no'] ?? argsMap['mobile'] ?? argsMap['phone'];

        setState(() {
          if (idCustomer != null && idCustomer.toString().isNotEmpty) {
            _idCustomer = idCustomer.toString();
            _isLoggedIn = true;
          }
          if (fullname != null && fullname.toString().isNotEmpty) {
            _fullname = fullname.toString();
          }
          if (gerai != null && gerai.toString().isNotEmpty) {
            _selectedGerai = gerai.toString();
            _fetchTerapis(_selectedGerai!);
          }
          // priority: mobile from args
          if (mobileFromArgs != null && mobileFromArgs.toString().isNotEmpty) {
            _mobileNoController.text = mobileFromArgs.toString();
          }
        });

        // if id_customer present and mobile not already set from args/prefs, fetch from server
        if (_idCustomer != null && (_mobileNoController.text.isEmpty)) {
          _fetchCustomerMobile(_idCustomer!);
        }
      }
      _argsProcessed = true;
    }
  }

  // load prefs; if id_customer exists here, fetch mobile from server
  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final customerId = prefs.getString('id_customer');
    final name = prefs.getString('fullname');
    final mobilePref = prefs.getString('mobile_no');

    setState(() {
      _isLoggedIn = loggedIn;
      _idCustomer = _idCustomer ?? customerId;
      _fullname = _fullname ?? name;

      // prefer controller value (args) then prefs
      if ((_mobileNoController.text.isEmpty) &&
          mobilePref != null &&
          mobilePref.isNotEmpty) {
        _mobileNoController.text = mobilePref;
      }
    });

    // if we now have id_customer (from prefs) and no mobile yet, fetch from server
    if (_idCustomer != null &&
        _idCustomer!.isNotEmpty &&
        _mobileNoController.text.isEmpty) {
      _fetchCustomerMobile(_idCustomer!);
    }
  }

  // fetch mobile_no from server using id_customer
  Future<void> _fetchCustomerMobile(String idCustomer) async {
    final url =
        Uri.parse('https://app.momnjo.com/api/get_customer.php?id=$idCustomer');
    try {
      debugPrint('[TambahScreen] fetching customer mobile for $idCustomer');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      debugPrint('[TambahScreen] get_customer status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        String? mobile;

        // tolerate a few possible response shapes:
        // 1) { "status":"success", "data": { "mobile_no": "0812..." } }
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map && decoded['data']['mobile_no'] != null) {
            mobile = decoded['data']['mobile_no'].toString();
          } else if (decoded['mobile_no'] != null) {
            mobile = decoded['mobile_no'].toString();
          } else if (decoded['data'] is Map &&
              decoded['data']['mobile'] != null) {
            mobile = decoded['data']['mobile'].toString();
          }
        }

        debugPrint('[TambahScreen] parsed mobile: $mobile');

        if (mobile != null && mobile.isNotEmpty) {
          setState(() {
            _mobileNoController.text = mobile!;
          });
        } else {
          debugPrint('[TambahScreen] mobile not found in response');
        }
      } else {
        debugPrint(
            '[TambahScreen] get_customer returned non-200: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception fetchCustomerMobile: $e');
    }
  }

  Future<void> _fetchGerai() async {
    final url = Uri.parse('https://app.momnjo.com/api/get_gerai_book.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> dataList = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data']
                : [];
        setState(() {
          _geraiList = dataList;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal mengambil data gerai: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exception: $e')));
    }
  }

  Future<void> _fetchTerapis(String kodeGerai) async {
    final url = Uri.parse(
        'https://app.momnjo.com/api/get_terapis.php?gerai=$kodeGerai');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> dataList = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List)
                ? decoded['data']
                : [];
        setState(() {
          _terapisList = dataList;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal mengambil data terapis: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exception: $e')));
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
    }
  }

  bool isDisabledTime(String slot) {
    if (_selectedDate != null &&
        DateUtils.isSameDay(_selectedDate!, DateTime.now())) {
      final parts = slot.split(":");
      final slotHour = int.tryParse(parts[0]) ?? 0;
      final slotMinute = int.tryParse(parts[1]) ?? 0;
      final now = TimeOfDay.now();
      if (slotHour < now.hour) return true;
      if (slotHour == now.hour && slotMinute < now.minute) return true;
    }
    return false;
  }

  Future<void> _submitData() async {
    if (!_isLoggedIn || _idCustomer == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Anda belum login!')));
      return;
    }
    if (_selectedDate == null ||
        _selectedTimeSlot == null ||
        _selectedGerai == null ||
        _selectedTerapis == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih tanggal, jam, gerai, dan terapis!')));
      return;
    }
    if (_mobileNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon tidak tersedia!')));
      return;
    }

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeString = '$_selectedTimeSlot:00';
    final remark = _remarkController.text.trim();

    try {
      final uri = Uri.parse('https://app.momnjo.com/api/tambah_transaksi.php');
      final response = await http.post(uri, body: {
        'tgl_dokumen': dateString,
        'jam': timeString,
        'deskripsi': remark,
        'customer': _idCustomer ?? '',
        'gerai': _selectedGerai ?? '',
        'mobile_no': _mobileNoController.text.trim(),
        'terapis': _selectedTerapis ?? '',
        'down_payment': '0',
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Mom N Joo - Konfirmasi Booking"),
              content: SingleChildScrollView(
                child: Text(
                  "Halo ${_fullname ?? ''}, terima kasih telah melakukan pemesanan treatment di Mom N Jo!\n\nAgar booking Anda dapat dikonfirmasi dan slot waktu tetap tersedia, mohon segera lakukan pembayaran booking fee sebesar IDR 100.000 ke [metode pembayaran].\n\nSetelah pembayaran dilakukan, silakan kirim bukti transfer ke [nomor WhatsApp/email]. Jika dalam 2 jam belum ada pembayaran, booking akan dibatalkan secara otomatis.\n\nTerima kasih, kami tunggu konfirmasi Anda!\n\n[Nama Spa & Kontak Anda]",
                  softWrap: true,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/booking', (route) => false);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result['message']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exception: $e')));
    }
  }

  Widget _buildFormContent() {
    final dateDisplay = _selectedDate == null
        ? 'Pilih Tanggal'
        : DateFormat('yyyy-MM-dd').format(_selectedDate!);

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
              // Nomor Telepon (read-only)
              TextFormField(
                controller: _mobileNoController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              // Dropdown Pilih Gerai
              DropdownButtonFormField<String>(
                value: _selectedGerai,
                decoration: InputDecoration(
                  labelText: 'Pilih Gerai',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _geraiList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['kode_gerai'],
                    child:
                        Text('${item['nama_gerai']} (${item['kode_gerai']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGerai = value;
                    if (value != null) _fetchTerapis(value);
                  });
                },
                hint: const Text('Pilih Gerai'),
              ),
              const SizedBox(height: 16),
              // Dropdown Pilih Terapis
              DropdownButtonFormField<String>(
                value: _selectedTerapis,
                decoration: InputDecoration(
                  labelText: 'Pilih Terapis',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: "any therapist", child: Text("any therapist")),
                  ..._terapisList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['username'],
                      child: Text(item['username']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTerapis = value;
                  });
                },
                hint: const Text('Pilih Terapis'),
              ),
              const SizedBox(height: 16),
              // Pilih Tanggal Booking
              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Booking',
                    prefixIcon: const Icon(Icons.date_range),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(dateDisplay),
                ),
              ),
              const SizedBox(height: 16),
              // Dropdown Pilih Jam Booking
              DropdownButtonFormField<String>(
                value: _selectedTimeSlot,
                decoration: InputDecoration(
                  labelText: 'Jam Booking',
                  prefixIcon: const Icon(Icons.access_time_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                hint: const Text('Pilih Jam Booking'),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem<String>(
                    value: slot,
                    child: Text(
                      slot,
                      style: TextStyle(
                          color: isDisabledTime(slot)
                              ? Colors.grey
                              : Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  if (isDisabledTime(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Waktu sudah lewat!')));
                    return;
                  }
                  setState(() {
                    _selectedTimeSlot = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Catatan / Keterangan
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: 'Catatan / Keterangan',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Tombol Submit
              ElevatedButton.icon(
                onPressed: _submitData,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB5C2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Text('Anda belum login!',
          style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Input Booking'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFFFE3EC), Color(0xFFFFF5F7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isLoggedIn
                    ? _buildFormContent()
                    : _buildNotLoggedInView()),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _mobileNoController.dispose();
    super.dispose();
  }
}
