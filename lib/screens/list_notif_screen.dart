import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ListNotifScreen extends StatefulWidget {
  const ListNotifScreen({Key? key}) : super(key: key);

  @override
  State<ListNotifScreen> createState() => _ListNotifScreenState();
}

class _ListNotifScreenState extends State<ListNotifScreen> {
  bool _isLoading = false;
  List<dynamic> _notifications = [];
  String _idCustomer = '';

  @override
  void initState() {
    super.initState();
    _loadCustomerAndFetch();
  }

  Future<void> _loadCustomerAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _idCustomer = prefs.getString('id_customer') ?? '';
    // jika id_customer kosong, masih panggil API tanpa param atau skip sesuai kebutuhan
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      "https://app.momnjo.com/api/get_notifications.php?id_customer=$_idCustomer",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _notifications = data;
        });
      } else {
        debugPrint("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(timestamp);
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      // jika format lain (mis. unix timestamp) coba parse numerik
      try {
        final maybeNum = int.tryParse(timestamp);
        if (maybeNum != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(maybeNum);
          return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        }
      } catch (_) {}
      return timestamp;
    }
  }

  Future<void> _markAsRead(String idNotif) async {
    final url = Uri.parse("https://app.momnjo.com/api/update_notification.php");

    try {
      final response = await http.post(url, body: {'id_notif': idNotif});
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          for (var notif in _notifications) {
            if (notif["id_notif"].toString() == idNotif) {
              notif["status_dibaca"] = "read";
            }
          }
        });
      } else {
        debugPrint(
            "Mark as read failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  void _navigateToDetail(Map<String, dynamic> notif) async {
    await _markAsRead(notif["id_notif"].toString());

    Navigator.pushNamed(
      context,
      '/NotificationDetailScreen',
      arguments: notif,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text("Tidak ada notifikasi"))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final bool isUnread = (notif["status_dibaca"] == null ||
                        notif["status_dibaca"].toString().isEmpty);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: isUnread ? Colors.blue : Colors.grey.shade600,
                        ),
                        title: Text(
                          notif["judul"] ?? "No Title",
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(notif["tanggal_notif"] ?? ""),
                          style: TextStyle(
                            color: isUnread ? Colors.blue : Colors.grey,
                          ),
                        ),
                        onTap: () =>
                            _navigateToDetail(Map<String, dynamic>.from(notif)),
                      ),
                    );
                  },
                ),
    );
  }
}
