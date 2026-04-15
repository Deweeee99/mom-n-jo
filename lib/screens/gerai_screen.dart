import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class GeraiScreen extends StatelessWidget {
  const GeraiScreen({super.key});

  // NOTE: jangan gunakan DNS lookup yang sensitif di emulator/device.
  // Langsung coba panggil endpoint API dan tangani error jaringan.
  Future<Map<String, dynamic>> fetchGeraiData(int branchId) async {
    if (branchId <= 0) {
      throw ArgumentError('Invalid branchId: $branchId');
    }

    final url = Uri.parse(
        'https://app.momnjo.com/api/get_gerai.php?id_gerai=$branchId');

    debugPrint('Fetching data for branch ID: $branchId');
    debugPrint('Request URL: ${url.toString()}');

    try {
      // jangan sertakan Content-Type pada GET kecuali perlu
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw HttpException('Gagal memuat data: ${response.statusCode}');
      }

      // parse JSON
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        // API Anda mengembalikan {"error":".."} saat tidak ada data
        if (decoded.containsKey('error')) {
          throw HttpException('API: ${decoded['error']}');
        }
        return decoded;
      } else {
        throw const FormatException('Format response tidak sesuai');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException -> no internet: $e');
      throw const NoInternetException();
    } on TimeoutException {
      debugPrint('TimeoutException');
      throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
    } on FormatException catch (e) {
      debugPrint('FormatException: $e');
      throw const FormatException('Format data tidak sesuai');
    } catch (e, st) {
      debugPrint('Unexpected error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  void _launchWhatsApp(String phoneNumber) async {
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
            const Icon(Icons.signal_wifi_off_outlined,
                color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF693D2C), // Warna tombol error ngikut tema utama
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int branchId = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
    final Color primaryColor = const Color(0xFF693D2C);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4), // Background peach muda
      extendBodyBehindAppBar: true, // Bikin gambar bisa tembus ke bawah App Bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparan biar gambar keliatan
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Bulatan tipis biar tombol back keliatan jelas
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchGeraiData(branchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text('Memuat data...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            String errorMessage = 'Terjadi kesalahan';
            final err = snapshot.error;
            if (err is NoInternetException) {
              errorMessage = 'Mohon maaf, internet tidak tersedia.\nSilakan periksa koneksi internet Anda.';
            } else if (err is TimeoutException) {
              errorMessage = 'Koneksi timeout.\nSilakan coba lagi.';
            } else if (err is SocketException) {
              errorMessage = 'Tidak dapat terhubung ke server.\nSilakan coba lagi nanti.';
            } else if (err is FormatException) {
              errorMessage = 'Format data tidak sesuai.\nSilakan coba lagi.';
            } else if (err is ArgumentError) {
              errorMessage = 'Parameter tidak valid: ${err.message}';
            } else if (err is HttpException) {
              errorMessage = 'Server merespons error: ${err.message}';
            } else {
              errorMessage = err.toString();
            }

            return _buildErrorWidget(errorMessage, () {
              (context as Element).markNeedsBuild();
            });
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildErrorWidget('Data tidak ditemukan',
                () => (context as Element).markNeedsBuild());
          }

          final geraiData = snapshot.data!;

          final String namaGerai = geraiData['nama_gerai']?.toString() ?? 'N/A';
          final String kontakGerai = geraiData['kontak_gerai']?.toString() ?? 'N/A';
          final String lokasiGerai = geraiData['lokasi_gerai']?.toString() ?? 'N/A';
          final String namaPerusahaan = geraiData['nama_perusahaan']?.toString() ?? 'N/A';
          final String kontakWa = geraiData['kontak_wa']?.toString() ?? '';
          final String kodeGerai = geraiData['kode_gerai']?.toString() ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER IMAGE MELENGKUNG (Sesuai Mockup)
                Container(
                  height: 320, // Tinggi gambar diatur biar pas
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
                    image: DecorationImage(
                      image: AssetImage('assets/darmawangsa.png'), // Fallback ke image asset
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. CARD INFORMASI (Posisi ditarik ke atas biar overlap sama gambar)
                Transform.translate(
                  offset: const Offset(0, -40), // Tarik ke atas 40 pixel
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // NAMA & KODE GERAI
                        Text(
                          namaGerai,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kodeGerai.isNotEmpty ? 'Kode: $kodeGerai' : 'Kode: -',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        const SizedBox(height: 16),
                        
                        // LOKASI
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lokasiGerai,
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // TELEPON
                        Row(
                          children: [
                            Icon(Icons.phone_in_talk_outlined, color: Colors.grey.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                kontakGerai,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // NAMA PERUSAHAAN (MOM N JO)
                        Row(
                          children: [
                            Icon(Icons.store_mall_directory_outlined, color: Colors.grey.shade600, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                namaPerusahaan,
                                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // TOMBOL WHATSAPP
                        if (kontakWa.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _launchWhatsApp(kontakWa),
                              // Pake icon chat biasa aja kalau gaada asset icon WA
                              icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
                              label: const Text(
                                'Hubungi via WhatsApp',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50), // Ijo WhatsApp
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
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

                // 3. TOMBOL KEMBALI
                Transform.translate(
                  offset: const Offset(0, -20), // Nyesuain jarak overlap
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
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

class NoInternetException implements Exception {
  const NoInternetException();
}