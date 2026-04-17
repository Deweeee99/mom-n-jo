class ApiConfig {
  // BRAY: Kalau mau ngetes pake API temen lu, biarin 'true'
  // Nanti kalau aplikasi udah siap rilis/on-air, ganti jadi 'false'
  static const bool isDevelopment = true; 

  // Base URL dari Tuan
  static const String _urlProduction = 'https://app.momnjo.com';
  static const String _urlDevelopment = 'https://app.momnjo.com/dev';

  // Ini magic-nya Tuan! Dia bakal otomatis milih URL sesuai status isDevelopment di atas
  static String get baseUrl {
    if (isDevelopment) {
      return _urlDevelopment;
    }
    return _urlProduction;
  }
}