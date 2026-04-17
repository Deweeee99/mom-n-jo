import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path; // gunakan alias 'path' untuk menghindari konflik

class UploadPaymentScreen extends StatefulWidget {
  final String idTransaksi; // id_transaksi untuk diupdate

  const UploadPaymentScreen({Key? key, required this.idTransaksi})
      : super(key: key);

  @override
  _UploadPaymentScreenState createState() => _UploadPaymentScreenState();
}

class _UploadPaymentScreenState extends State<UploadPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nominalController =
      TextEditingController(text: "100000"); // Default DP
  String? _metodeTransfer;
  File? _buktiTransfer;
  bool _isUploading = false;
  
  final List<String> _bankOptions = [
    "BCA",
    "Mandiri",
    "BRI",
    "BNI",
    "Bank Lainnya"
  ];

  // Tema Warna Desain Baru
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Muda Background
  final Color _btnColor = const Color(0xFFDBA38C); // Warna Peach/Coral Tombol

  // Fungsi memilih gambar
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _buktiTransfer = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    // Debug: cek nilai idTransaksi
    debugPrint("ID Transaksi yang dikirim: ${widget.idTransaksi}");

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data!')),
      );
      return;
    }

    if (_buktiTransfer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bukti transfer terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://app.momnjo.com/api/upload_pembayaran.php'),
      );
      request.fields['id_transaksi'] = widget.idTransaksi;
      request.fields['metode_transfer'] = _metodeTransfer ?? '';
      request.fields['nominal'] = _nominalController.text.trim();

      // Kirim file sebagai bytes
      List<int> imageBytes = await _buktiTransfer!.readAsBytes();
      String filename = path.basename(_buktiTransfer!.path);
      request.files.add(http.MultipartFile.fromBytes(
        'bukti_transfer',
        imageBytes,
        filename: filename,
      ));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);
      debugPrint("Response: ${responseBody.body}");

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil diupload.'),
              backgroundColor: Colors.green,
            ),
          );
          // ---> BRAY: INI OBATNYA! Cukup Pop biar balik ke History yang nungguin dan otomatis nampilin footer lagi <---
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal upload pembayaran: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  // Helper untuk form input estetik
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAD8C0), // Warna krem
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
        title: Text(
          'Upload Pembayaran',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Tipis
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bookbg.png'), // Background senada
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: _btnColor),
                        const SizedBox(height: 12),
                        Text(
                          'ID TRANSAKSI',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.idTransaksi,
                          style: TextStyle(fontSize: 18, color: _primaryColor, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Upload
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nominal Transfer
                          TextFormField(
                            controller: _nominalController,
                            decoration: _customInputDecoration('Nominal Transfer (Rp)', Icons.attach_money),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'Masukkan nominal pembayaran'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Dropdown Bank
                          DropdownButtonFormField<String>(
                            value: _metodeTransfer,
                            decoration: _customInputDecoration('Metode Transfer (Bank)', Icons.account_balance_outlined),
                            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                            items: _bankOptions.map((bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _metodeTransfer = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Pilih metode transfer' : null,
                          ),
                          const SizedBox(height: 24),

                          // Area Bukti Transfer
                          Text(
                            'Bukti Transfer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9EAE1), // Peach tipis
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _btnColor, width: 1.5, style: BorderStyle.solid),
                              ),
                              child: _buktiTransfer != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _buktiTransfer!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cloud_upload_outlined, size: 40, color: _primaryColor.withOpacity(0.6)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tap untuk unggah gambar',
                                          style: TextStyle(
                                            color: _primaryColor.withOpacity(0.8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tombol Submit
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _submitPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _btnColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Kirim Pembayaran',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}