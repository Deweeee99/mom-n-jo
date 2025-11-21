import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart'
    as path; // gunakan alias 'path' untuk menghindari konflik

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
      TextEditingController(text: "100000");
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
    print("ID Transaksi yang dikirim: ${widget.idTransaksi}");

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data!')),
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

      // Jika gambar sudah dipilih, kirim file sebagai bytes
      if (_buktiTransfer != null) {
        List<int> imageBytes = await _buktiTransfer!.readAsBytes();
        String filename = path.basename(_buktiTransfer!.path);
        request.files.add(http.MultipartFile.fromBytes(
          'bukti_transfer',
          imageBytes,
          filename: filename,
        ));
      }
      // Jika tidak memilih gambar, tidak perlu mengirim field file

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);
      print("Response: ${responseBody.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran berhasil diupload.')));
        // Alihkan ke halaman booking
        Navigator.pushReplacementNamed(context, '/booking');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal upload pembayaran: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown pilihan metode transfer (bank)
              DropdownButtonFormField<String>(
                value: _metodeTransfer,
                decoration: const InputDecoration(
                  labelText: 'Metode Transfer (Bank)',
                ),
                items: _bankOptions.map((bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank),
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
              const SizedBox(height: 16),
              // TextField untuk nominal pembayaran
              TextFormField(
                controller: _nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal Pembayaran',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Masukkan nominal pembayaran'
                    : null,
              ),
              const SizedBox(height: 16),
              // Tombol pilih bukti transfer
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pilih Bukti Transfer'),
              ),
              const SizedBox(height: 8),
              _buktiTransfer != null
                  ? Image.file(
                      _buktiTransfer!,
                      height: 150,
                    )
                  : const Text('Belum ada bukti transfer yang dipilih.'),
              const SizedBox(height: 24),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitPayment,
                      child: const Text('Kirim Pembayaran'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
