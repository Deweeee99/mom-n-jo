import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class GeraiScreen extends StatelessWidget {
  const GeraiScreen({super.key});

  Future<bool> checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>> fetchGeraiData(int branchId) async {
    try {
      bool hasInternet = await checkInternet();
      if (!hasInternet) {
        throw const NoInternetException();
      }

      debugPrint('Fetching data for branch ID: $branchId');

      final url = Uri.parse(
        'https://app.momnjo.com/api/get_gerai.php?id_gerai=$branchId',
      );

      debugPrint('Request URL: ${url.toString()}');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        } else {
          throw const FormatException('Format response tidak sesuai');
        }
      } else {
        throw HttpException('Gagal memuat data: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
    } on SocketException {
      throw const SocketException('Tidak dapat terhubung ke server');
    } on FormatException {
      throw const FormatException('Format data tidak sesuai');
    } catch (e, stackTrace) {
      debugPrint('Error fetching data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Fungsi untuk meluncurkan WA
  void _launchWhatsApp(String phoneNumber) async {
    // Pastikan nomor sudah dalam format internasional, misalnya "6281234567890"
    final url = "https://wa.me/$phoneNumber";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.signal_wifi_off_outlined,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4B89C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int branchId =
        ModalRoute.of(context)?.settings.arguments as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4B89C),
        elevation: 0,
        title: const Text(
          'Detail Gerai',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchGeraiData(branchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFD4B89C),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            String errorMessage = 'Terjadi kesalahan';

            if (snapshot.error is NoInternetException) {
              errorMessage =
                  'Mohon maaf, internet tidak tersedia.\nSilakan periksa koneksi internet Anda.';
            } else if (snapshot.error is TimeoutException) {
              errorMessage = 'Koneksi timeout.\nSilakan coba lagi.';
            } else if (snapshot.error is SocketException) {
              errorMessage =
                  'Tidak dapat terhubung ke server.\nSilakan coba lagi nanti.';
            } else if (snapshot.error is FormatException) {
              errorMessage = 'Format data tidak sesuai.\nSilakan coba lagi.';
            }

            return _buildErrorWidget(
              errorMessage,
              () => (context as Element).markNeedsBuild(),
            );
          } else if (!snapshot.hasData || snapshot.data!.containsKey('error')) {
            return _buildErrorWidget(
              'Data tidak ditemukan',
              () => (context as Element).markNeedsBuild(),
            );
          }

          final geraiData = snapshot.data!;

          // Ambil data-data yang diperlukan
          final String namaGerai = geraiData['nama_gerai'] ?? 'N/A';
          final String kontakGerai = geraiData['kontak_gerai'] ?? 'N/A';
          final String lokasiGerai = geraiData['lokasi_gerai'] ?? 'N/A';
          final String namaPerusahaan = geraiData['nama_perusahaan'] ?? 'N/A';
          final String kontakWa = geraiData['kontak_wa'] ?? '';

          final String kodeGerai = geraiData['kode_gerai'] ?? 'N/A';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bagian Header dengan background
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4B89C),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Gambar bulat atau avatar gerai
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              // Ganti gambar sesuai kebutuhan. Bisa diganti ke network jika ada foto gerai
                              'assets/darmawangsa.png',
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Card detail gerai
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            namaGerai,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF693D2C),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Kode Gerai
                          Text(
                            kodeGerai.isNotEmpty
                                ? 'Kode: $kodeGerai'
                                : 'Kode: -',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Divider(height: 30, color: Colors.grey),

                          // Lokasi Gerai
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lokasiGerai,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Kontak Gerai
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_in_talk_outlined,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  kontakGerai,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Nama Perusahaan
                          Row(
                            children: [
                              const Icon(
                                Icons.store_mall_directory_outlined,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  namaPerusahaan,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          // Tombol WA jika kontak_wa tidak kosong
                          if (kontakWa.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _launchWhatsApp(kontakWa);
                                },
                                // GANTI Icon(...) dengan Image.asset(...)
                                icon: Image.asset(
                                  'assets/wa.png',
                                  height: 24,
                                  width: 24,
                                ),
                                label: const Text('Hubungi via WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tombol Kembali
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom exception for no internet connection
class NoInternetException implements Exception {
  const NoInternetException();
}
