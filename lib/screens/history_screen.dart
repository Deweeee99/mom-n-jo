import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _idCustomer = ''; // id_customer from SharedPreferences
  List<dynamic> _listTransaksi = [];

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String idCustomer = prefs.getString('id_customer') ?? '';

    if (!loggedIn || idCustomer.isEmpty) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _idCustomer = idCustomer;
    });

    await _fetchTransaksi(idCustomer);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchTransaksi(String customerId) async {
    try {
      final url = Uri.parse(
          'https://app.momnjo.com/api/get_history.php?id_customer=$customerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _listTransaksi = data;
        });
      } else {
        print('Failed to load data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Widget _buildTransaksiCard(Map<String, dynamic> trx) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.brown),
        title: Text('Transaksi #${trx['id_transaksi']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tgl Dokumen: ${trx['tgl_dokumen']}'),
            Text('Jam: ${trx['jam']}'),
            Text('Terapis: ${trx['id_terapis']}'),
            Text('Deskripsi: ${trx['deskripsi']}'),
            Text('Status: ${trx['status']}'),
            Text('Customer: ${trx['customer']}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('History Booking')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Anda belum login.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login Dulu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History Booking')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bookbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _listTransaksi.isEmpty
            ? const Center(child: Text('Data transaksi kosong.'))
            : ListView.builder(
                itemCount: _listTransaksi.length,
                itemBuilder: (context, index) =>
                    _buildTransaksiCard(_listTransaksi[index]),
              ),
      ),
    );
  }
}
