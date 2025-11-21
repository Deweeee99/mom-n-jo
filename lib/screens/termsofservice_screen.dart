import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF693D2C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Syarat dan Ketentuan',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        // Background image untuk kesan elegan
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Overlay putih agar teks terbaca dengan jelas
          color: Colors.white.withOpacity(0.9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul halaman
                Center(
                  child: Text(
                    'Syarat dan Ketentuan Penggunaan Aplikasi Momnjo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Terakhir diperbarui: 20/11/2025',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('1. Definisi', primaryColor),
                _buildSectionContent(
                  'Aplikasi: Merujuk pada platform digital Momnjo yang menyediakan layanan pijat bayi, spa bayi, pijat hamil, dan pregnancy massage.\n'
                  'Pengguna: Setiap individu yang mengakses atau menggunakan Aplikasi.\n'
                  'Layanan: Semua layanan yang disediakan melalui Aplikasi, termasuk namun tidak terbatas pada pemesanan layanan pijat dan konsultasi terkait kesehatan ibu dan bayi.\n'
                  'Konten: Segala informasi, data, teks, gambar, video, atau materi lain yang disajikan dalam Aplikasi.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('2. Penerimaan Syarat', primaryColor),
                _buildSectionContent(
                  'Dengan mengunduh, menginstal, atau menggunakan Aplikasi Momnjo, Anda menyatakan bahwa Anda telah membaca, memahami, dan setuju untuk terikat oleh Syarat dan Ketentuan ini, serta semua kebijakan dan pedoman operasional yang diterbitkan oleh Kami dari waktu ke waktu.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('3. Deskripsi Layanan', primaryColor),
                _buildSectionContent(
                  'Aplikasi Momnjo menyediakan platform untuk:\n\n'
                  '• Pemesanan layanan pijat bayi, spa bayi, pijat hamil, dan pregnancy massage.\n'
                  '• Menyediakan informasi dan panduan terkait perawatan bayi dan kesehatan ibu selama kehamilan.\n'
                  '• Menghubungkan pengguna dengan praktisi profesional yang telah terverifikasi.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('4. Persyaratan Pengguna', primaryColor),
                _buildSectionContent(
                  'Usia Pengguna: Pengguna harus berusia minimal 18 tahun atau telah mendapatkan izin dari orang tua/wali apabila diizinkan oleh hukum yang berlaku.\n'
                  'Kepatuhan: Pengguna wajib menggunakan Aplikasi sesuai dengan hukum dan peraturan yang berlaku serta tidak menyalahgunakan layanan.\n'
                  'Akun Pengguna: Pengguna bertanggung jawab untuk menjaga kerahasiaan informasi akun dan password. Setiap aktivitas yang terjadi di dalam akun dianggap sebagai tanggung jawab pengguna.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('5. Penggunaan Layanan', primaryColor),
                _buildSectionContent(
                  'Pemesanan Layanan: Semua pemesanan layanan melalui Aplikasi harus dilakukan sesuai dengan prosedur yang telah ditetapkan. Konfirmasi pemesanan dapat dilakukan melalui notifikasi di aplikasi, email, atau SMS.\n'
                  'Pembayaran: Pembayaran atas layanan yang dipesan dilakukan melalui metode pembayaran yang disediakan. Semua transaksi bersifat final dan tidak dapat dibatalkan kecuali ditentukan lain dalam ketentuan khusus.\n'
                  'Perubahan dan Pembatalan: Ketentuan mengenai perubahan atau pembatalan layanan dapat berbeda-beda, tergantung pada jenis layanan. Informasi lebih lanjut tersedia di halaman pemesanan masing-masing.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('6. Hak Kekayaan Intelektual', primaryColor),
                _buildSectionContent(
                  'Kepemilikan: Seluruh konten, merek dagang, logo, dan materi lain yang terdapat dalam Aplikasi adalah milik [Nama Perusahaan/Entitas] atau pihak ketiga yang memberikan lisensi kepada Kami.\n'
                  'Larangan Penyalinan: Pengguna dilarang menyalin, mendistribusikan, atau menggunakan konten Aplikasi tanpa izin tertulis dari pemilik hak cipta.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('7. Batasan Tanggung Jawab', primaryColor),
                _buildSectionContent(
                  'Penolakan Jaminan: Layanan disediakan "sebagaimana adanya" tanpa jaminan apa pun, baik tersurat maupun tersirat, termasuk tetapi tidak terbatas pada jaminan kelayakan, kesesuaian untuk tujuan tertentu, dan non-pelanggaran.\n'
                  'Kerugian: Kami tidak bertanggung jawab atas kerugian atau kerusakan yang timbul dari penggunaan atau ketidakmampuan untuk menggunakan Aplikasi, termasuk gangguan layanan atau kesalahan teknis.\n'
                  'Kesehatan dan Keamanan: Informasi yang disediakan dalam Aplikasi tidak menggantikan nasihat profesional medis. Pengguna disarankan untuk berkonsultasi dengan tenaga medis terkait sebelum mengambil keputusan kesehatan.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('8. Privasi', primaryColor),
                _buildSectionContent(
                  'Penggunaan Aplikasi juga tunduk pada Kebijakan Privasi kami yang mengatur pengumpulan, penggunaan, dan perlindungan data pribadi pengguna. Silakan baca Kebijakan Privasi untuk informasi lebih lanjut.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(
                  '9. Tautan ke Situs/Pihak Ketiga',
                  primaryColor,
                ),
                _buildSectionContent(
                  'Aplikasi Momnjo mungkin mengandung tautan ke situs atau layanan pihak ketiga. Kami tidak bertanggung jawab atas konten atau praktik privasi situs/sumber daya tersebut. Penggunaan tautan tersebut sepenuhnya menjadi tanggung jawab pengguna.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(
                  '10. Perubahan pada Syarat dan Ketentuan',
                  primaryColor,
                ),
                _buildSectionContent(
                  'Kami berhak untuk mengubah atau memperbarui Syarat dan Ketentuan ini setiap saat tanpa pemberitahuan terlebih dahulu. Perubahan akan berlaku segera setelah dipublikasikan di Aplikasi. Penggunaan berkelanjutan Aplikasi setelah perubahan tersebut dianggap sebagai persetujuan terhadap Syarat dan Ketentuan yang baru.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(
                  '11. Hukum yang Mengatur dan Penyelesaian Sengketa',
                  primaryColor,
                ),
                _buildSectionContent(
                  'Hukum yang Berlaku: Syarat dan Ketentuan ini diatur oleh dan ditafsirkan sesuai dengan hukum yang berlaku di Republik Indonesia.\n'
                  'Penyelesaian Sengketa: Setiap perselisihan yang timbul dari atau berkaitan dengan Syarat dan Ketentuan ini akan diselesaikan melalui musyawarah terlebih dahulu. Jika tidak tercapai kesepakatan, sengketa akan diselesaikan melalui jalur hukum di wilayah hukum yang berlaku.',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('12. Kontak', primaryColor),
                _buildSectionContent(
                  'Jika Anda memiliki pertanyaan atau memerlukan klarifikasi mengenai Syarat dan Ketentuan ini, silakan hubungi kami di:\n\n'
                  'Email: support@momnjo.com\n'
                  'Telepon: (021) 72780760\n'
                  'Alamat: Jl. Darmawangsa IV No.8, RT.1/RW.1, Pulo, Kec. Kby. Baru, Kota Jakarta Selatan, Daerah Khusus Ibukota Jakarta 12160\n\n'
                  'Dengan menggunakan Aplikasi Momnjo, Anda menyatakan bahwa Anda telah membaca, memahami, dan setuju untuk terikat oleh seluruh Syarat dan Ketentuan di atas.',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk judul setiap section
  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  // Widget untuk isi konten setiap section
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}
