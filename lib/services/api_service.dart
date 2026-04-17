import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // ==========================================
  // 1. MESIN UTAMA (BASE REQUEST)
  // ==========================================
  // Semua request POST bakal lewat sini, jadi gausah nulis ulang try-catch
  Future<Map<String, dynamic>> _postRequest(String endpoint, Map<String, dynamic> body) async {
    // Otomatis gabungin Base URL + Endpoint (contoh: https://app.momnjo.com/dev + /api/login.php)
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await http.post(
        url,
        body: body, // Data yang dikirim dilempar ke sini
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Server lagi ngambek nih Tuan (Code: ${response.statusCode})'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Gagal konek: $e'
      };
    }
  }

  // ==========================================
  // 2. DAFTAR ENDPOINT LU (JADI SUPER PENDEK!)
  // ==========================================

  // Fungsi Login
  Future<Map<String, dynamic>> loginCustomer(String phone, String password) async {
    return await _postRequest('/api/login.php', {
      'mobile_no': phone,
      'password': password,
    });
  }

  // Contoh bayangan kalau nanti lu mau nambah fitur lain:
  /*
  // Fungsi Register
  Future<Map<String, dynamic>> registerCustomer(String name, String phone) async {
    return await _postRequest('/api/register.php', {
      'fullname': name,
      'mobile_no': phone,
    });
  }

  // Fungsi Update Profile
  Future<Map<String, dynamic>> updateProfile(String id, String email) async {
    return await _postRequest('/api/update_profile.php', {
      'id_customer': id,
      'email': email,
    });
  }
  */
}