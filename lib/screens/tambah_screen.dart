import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Clipboard
import 'package:url_launcher/url_launcher.dart';

class TambahScreen extends StatefulWidget {
  const TambahScreen({super.key});

  @override
  State<TambahScreen> createState() => _TambahScreenState();
}

class _TambahScreenState extends State<TambahScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();

  List<dynamic> _geraiList = [];
  String? _selectedGerai;

  List<dynamic> _terapisList = [];
  String? _selectedTerapis;

  Map<String, dynamic>? _identitasData;

  bool _isLoggedIn = false;
  String? _idCustomer;
  String? _fullname;

  bool _argsProcessed = false;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
    "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00",
  ];

  // simpan selected treatments dari BookingDetail
  List<Map<String, dynamic>> _selectedTreatments = [];

  // Warna Tema Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _btnColor = const Color(0xFFDBA38C); // Warna Peach/Coral Tombol

  @override
  void initState() {
    super.initState();
    _loadLoginData();
    _fetchGerai();
    _fetchIdentitas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsProcessed) {
      final argsRaw = ModalRoute.of(context)?.settings.arguments;
      Map<String, dynamic>? argsMap;

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

      if (argsMap != null) {
        if (argsMap['selectedTreatments'] != null &&
            argsMap['selectedTreatments'] is List) {
          try {
            _selectedTreatments = (argsMap['selectedTreatments'] as List)
                .map((e) {
                  if (e is Map<String, dynamic>) return Map<String, dynamic>.from(e);
                  if (e is Map) return Map<String, dynamic>.from(e);
                  return <String, dynamic>{};
                })
                .where((m) => m.isNotEmpty)
                .toList();
          } catch (e) {
            debugPrint('[TambahScreen] error parsing selectedTreatments: $e');
          }
        }

        final idCustomer = argsMap['id_customer'] ?? argsMap['idCustomer'] ?? argsMap['customer'];
        final fullname = argsMap['fullname'] ?? argsMap['full_name'] ?? argsMap['name'];
        final gerai = argsMap['gerai'] ?? argsMap['kode_gerai'] ?? argsMap['kodeGerai'];
        final mobileFromArgs = argsMap['mobile_no'] ?? argsMap['mobile'] ?? argsMap['phone'];

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
          if (mobileFromArgs != null && mobileFromArgs.toString().isNotEmpty) {
            _mobileNoController.text = mobileFromArgs.toString();
          }
        });

        if (_idCustomer != null && (_mobileNoController.text.isEmpty)) {
          _fetchCustomerMobile(_idCustomer!);
        }
      }
      _argsProcessed = true;
    }
  }

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

      if ((_mobileNoController.text.isEmpty) &&
          mobilePref != null &&
          mobilePref.isNotEmpty) {
        _mobileNoController.text = mobilePref;
      }
    });

    if (_idCustomer != null &&
        _idCustomer!.isNotEmpty &&
        _mobileNoController.text.isEmpty) {
      _fetchCustomerMobile(_idCustomer!);
    }
  }

  Future<void> _fetchCustomerMobile(String idCustomer) async {
    final url = Uri.parse('https://app.momnjo.com/api/get_customer.php?id=$idCustomer');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        String? mobile;

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map && decoded['data']['mobile_no'] != null) {
            mobile = decoded['data']['mobile_no'].toString();
          } else if (decoded['mobile_no'] != null) {
            mobile = decoded['mobile_no'].toString();
          } else if (decoded['data'] is Map && decoded['data']['mobile'] != null) {
            mobile = decoded['data']['mobile'].toString();
          }
        }

        if (mobile != null && mobile.isNotEmpty) {
          setState(() {
            _mobileNoController.text = mobile!;
          });
        }
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception fetchCustomerMobile: $e');
    }
  }

  Future<void> _fetchGerai() async {
    final url = Uri.parse('https://app.momnjo.com/api/get_gerai_book.php');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
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
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception _fetchGerai: $e');
    }
  }

  Future<void> _fetchTerapis(String kodeGerai) async {
    final url = Uri.parse('https://app.momnjo.com/api/get_terapis.php?gerai=$kodeGerai');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
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
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception _fetchTerapis: $e');
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
            _identitasData = Map<String, dynamic>.from(decoded['data'] as Map<String, dynamic>);
          });
        }
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception fetchIdentitas: $e');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black87, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
    }
  }

  bool isDisabledTime(String slot) {
    if (_selectedDate != null && DateUtils.isSameDay(_selectedDate!, DateTime.now())) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda belum login!')));
      return;
    }
    if (_selectedDate == null || _selectedTimeSlot == null || _selectedGerai == null || _selectedTerapis == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal, jam, gerai, dan terapis!')));
      return;
    }
    if (_mobileNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor telepon tidak tersedia!')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeString = '$_selectedTimeSlot:00';
    final remark = _remarkController.text.trim();

    List<Map<String, dynamic>> detail;
    if (_selectedTreatments.isNotEmpty) {
      detail = _selectedTreatments.map((t) {
        final idItem = t['idItem'] ?? t['id_item_master'] ?? t['id'] ?? '';
        final name = t['nama_item_master'] ?? t['nama_item'] ?? t['product_name'] ?? '';
        final qty = (t['qty'] is int) ? t['qty'] : int.tryParse((t['qty'] ?? '1').toString()) ?? 1;
        final price = (t['product_price'] is int) ? t['product_price'] : int.tryParse((t['product_price'] ?? '0').toString()) ?? 0;
        return {'idItem': idItem, 'nama_item_master': name, 'qty': qty, 'product_price': price};
      }).toList();
    } else {
      detail = [
        {'idItem': 'BOOKINGFEE', 'nama_item_master': 'Booking Fee', 'qty': 1, 'product_price': 100000}
      ];
    }

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
        'detail': jsonEncode(detail),
      }).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          // Ngambil identitas sesuai API bawaan mentor lu
          final namaSpa = _identitasData?['nama_website']?.toString() ?? 'Mom N Jo';
          final rekening = _identitasData?['rekening']?.toString() ?? '[metode pembayaran]';
          final wa = _identitasData?['whatsapp']?.toString() ?? '';
          final email = _identitasData?['email']?.toString() ?? '';
          final noTelp = _identitasData?['no_telp']?.toString() ?? '';

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

          // Pesan murni 100% sama persis kaya kodingan lu
          final pesanKonfirmasi = """
Halo ${_fullname ?? ''}, terima kasih telah melakukan pemesanan treatment di $namaSpa!

Agar booking Anda dapat dikonfirmasi dan slot waktu tetap tersedia, mohon segera lakukan pembayaran booking fee sebesar IDR 100.000 ke:
$rekening

Setelah pembayaran dilakukan, silakan kirim bukti transfer ke $kontakKonfirmasi. Jika dalam 2 jam belum ada pembayaran, booking akan dibatalkan secara otomatis.

Terima kasih, kami tunggu konfirmasi Anda!

$namaSpa
$noTelp
""";

          // --- CUSTOM DIALOG UI DENGAN TEKS MENTOR LU ---
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Centang Hijau
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 45),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      "Mom N Jo - Booking\nTerkonfirmasi!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _primaryColor,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Teks Asli dari Mentor
                    Text(
                      "Halo ${_fullname ?? ''}, terima kasih telah melakukan pemesanan treatment di $namaSpa!\n\nAgar booking Anda dapat dikonfirmasi dan slot waktu tetap tersedia, mohon segera lakukan pembayaran booking fee sebesar IDR 100.000 ke:",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    
                    // Card Rekening
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF8F4), // Peach background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, color: _btnColor, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              rekening,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sisa Instruksi Text dari Mentor
                    Text(
                      "Setelah pembayaran dilakukan, silakan kirim bukti transfer ke $kontakKonfirmasi. Jika dalam 1 jam belum ada pembayaran, booking akan dibatalkan secara otomatis.\n\nTerima kasih, kami tunggu konfirmasi Anda!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    // TOMBOL-TOMBOL SESUAI BAWAAN MENTOR TAPI DIBIKIN MODERN
                    
                    // 1. Tombol Salin Rekening
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     icon: Icon(Icons.copy, size: 18, color: _primaryColor),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: _primaryColor,
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       side: BorderSide(color: _primaryColor, width: 1.5),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    //     ),
                    //     onPressed: () {
                    //       Clipboard.setData(ClipboardData(text: rekening));
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(content: Text('Rekening disalin ke clipboard'))
                    //       );
                    //     },
                    //     label: const Text("Salin Rekening", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    //   ),
                    // ),
                    const SizedBox(height: 8),

                    // 2. Tombol Kirim via WA (Kalo ada WA)
                    // if (wa.isNotEmpty)
                    //   SizedBox(
                    //     width: double.infinity,
                    //     child: ElevatedButton.icon(
                    //       icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.green, // Hijau WA
                    //         foregroundColor: Colors.white,
                    //         padding: const EdgeInsets.symmetric(vertical: 12),
                    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    //         elevation: 0,
                    //       ),
                    //       onPressed: () {
                    //         _openWhatsAppWithMessage(wa, pesanKonfirmasi);
                    //       },
                    //       label: const Text('Kirim via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    //     ),
                    //   ),
                    const SizedBox(height: 8),

                    // 3. Tombol Kembali / OK
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                        },
                        child: const Text('Kembali ke Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['message'] ?? 'unknown'}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
      }
    } catch (e) {
      debugPrint('[TambahScreen] Exception _submitData: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exception: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _openWhatsAppWithMessage(String waNumber, String message) async {
    var number = waNumber.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    final encoded = Uri.encodeComponent(message);
    final waUrl = Uri.parse('https://wa.me/$number?text=$encoded');

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
    }
  }

  // --- HELPER WIDGETS ---
  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _primaryColor.withOpacity(0.7), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final dateDisplay = _selectedDate == null
        ? 'Pilih Tanggal'
        : DateFormat('dd MMM yyyy').format(_selectedDate!);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP READ-ONLY INFO
            _buildReadOnlyRow(Icons.person_outline, 'Nama Pelanggan', _fullname ?? 'No Name'),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),
            
            _buildReadOnlyRow(Icons.numbers, 'ID Customer', _idCustomer ?? '-'),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),
            
            _buildReadOnlyRow(Icons.phone_outlined, 'Nomor Telepon', _mobileNoController.text.isNotEmpty ? _mobileNoController.text : '-'),
            const SizedBox(height: 24),

            // INPUT GERAI
            DropdownButtonFormField<String>(
              value: _selectedGerai,
              decoration: _customInputDecoration('Pilih Gerai', Icons.store_outlined),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              items: _geraiList.map((item) {
                return DropdownMenuItem<String>(
                  value: item['kode_gerai']?.toString(),
                  child: Text('${item['nama_gerai']}'),
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

            // INPUT TERAPIS
            DropdownButtonFormField<String>(
              value: _selectedTerapis,
              decoration: _customInputDecoration('Pilih Terapis', Icons.face_retouching_natural),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              items: [
                const DropdownMenuItem<String>(value: "any therapist", child: Text("Any Therapist")),
                ..._terapisList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['username']?.toString(),
                    child: Text(item['username']?.toString() ?? ''),
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

            // DATE & TIME (Side by side for better look, or stacked)
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _customInputDecoration('Tanggal Booking', Icons.calendar_month_outlined),
                child: Text(
                  dateDisplay,
                  style: TextStyle(color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedTimeSlot,
              decoration: _customInputDecoration('Jam Booking', Icons.access_time_outlined),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              hint: const Text('Pilih Jam Booking'),
              items: _timeSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot,
                  child: Text(slot, style: TextStyle(color: isDisabledTime(slot) ? Colors.grey.shade400 : Colors.black87)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                if (isDisabledTime(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waktu sudah lewat!')));
                  return;
                }
                setState(() {
                  _selectedTimeSlot = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // REMARKS
            TextFormField(
              controller: _remarkController,
              decoration: _customInputDecoration('Catatan / Keterangan', Icons.note_alt_outlined),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // Pill shape
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: _primaryColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Akses Ditolak',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
          ),
          const SizedBox(height: 8),
          const Text('Silakan login terlebih dahulu untuk membuat pesanan.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna solid krim
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        title: Text(
          'Input Booking',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isLoggedIn ? _buildFormContent() : _buildNotLoggedInView(),
              ),
            ),
          ),
        ],
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