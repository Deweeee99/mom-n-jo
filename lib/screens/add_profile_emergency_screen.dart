import 'package:flutter/material.dart';

// Model buat nampung data tiap-tiap kontak darurat yang ditambahin
class EmergencyContact {
  TextEditingController nameController = TextEditingController();
  String? relationship;
  TextEditingController phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class AddProfileEmergencyScreen extends StatefulWidget {
  final Map<String, dynamic>? personalData; // Nangkep data dari screen sebelumnya

  const AddProfileEmergencyScreen({super.key, this.personalData});

  @override
  State<AddProfileEmergencyScreen> createState() => _AddProfileEmergencyScreenState();
}

class _AddProfileEmergencyScreenState extends State<AddProfileEmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // List buat nampung form kontak (default ada 1)
  final List<EmergencyContact> _contacts = [EmergencyContact()];

  // Tema Warna Sesuai Mockup
  final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
  final Color _bgColor = const Color(0xFFFDF8F4); // Peach Background
  final Color _btnDarkColor = const Color(0xFF4A2E20); // Coklat Gelap Tombol Continue
  final Color _greenColor = const Color(0xFF5A7B5E); // Hijau khas MomNJo (Daun)

  final List<String> _relationshipOptions = [
    'Spouse (Suami/Istri)',
    'Parent (Orang Tua)',
    'Sibling (Saudara)',
    'Friend (Teman)',
    'Other (Lainnya)'
  ];

  @override
  void dispose() {
    for (var contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add(EmergencyContact());
    });
  }

  void _removeContact(int index) {
    setState(() {
      if (_contacts.length > 1) {
        _contacts[index].dispose();
        _contacts.removeAt(index);
      }
    });
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      // Kumpulin semua data kontak darurat
      List<Map<String, dynamic>> emergencyData = _contacts.map((c) => {
        'name': c.nameController.text,
        'relationship': c.relationship,
        'phone': c.phoneController.text,
      }).toList();

      // Gabungin data personal (screen 1) sama data emergency (screen 2)
      final allData = {
        ...?widget.personalData,
        'emergency_contacts': emergencyData,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lanjut ke Medical History...')),
      );

      // TODO: Arahin ke screen 3 (Medical History)
       Navigator.pushNamed(context, '/add_profile_medical', arguments: allData);
    }
  }

  // Label custom estetik kayak screen sebelumnya
  Widget _buildCustomLabel(String mainText, String subText, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: RichText(
        text: TextSpan(
          text: mainText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            fontFamily: 'serif',
          ),
          children: [
            TextSpan(
              text: ' $subText',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                fontStyle: isRequired ? FontStyle.normal : FontStyle.italic,
                color: isRequired ? Colors.red.shade700 : _primaryColor,
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/images/logo_momnjo.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) => Text(
            'mom n jo',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Background Garis
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_garis.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
          ),
          
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KONTEN BISA DI-SCROLL
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // JUDUL HALAMAN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Emergency Contact',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'serif',
                                  fontStyle: FontStyle.italic,
                                  color: _primaryColor,
                                ),
                              ),
                              const Icon(Icons.auto_awesome, color: Color(0xFFDBA38C), size: 24),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // LIST FORM KONTAK (Dynamic)
                          ...List.generate(_contacts.length, (index) {
                            return _buildContactCard(index);
                          }),

                          // TOMBOL ADD ANOTHER CONTACT
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _addContact,
                              icon: Icon(Icons.add_circle_outline, color: _greenColor),
                              label: Text(
                                'Add Another Contact',
                                style: TextStyle(
                                  color: _greenColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _greenColor,
                                side: BorderSide(color: _greenColor, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER TOMBOL BACK & CONTINUE (Fixed di bawah)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      boxShadow: [
                        BoxShadow(
                          color: _bgColor.withOpacity(0.8),
                          spreadRadius: 10,
                          blurRadius: 10,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Tombol Back
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Tombol Continue
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _btnDarkColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.eco, color: Color(0xFF8B9A76), size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'serif',
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(3.14159), 
                                  child: const Icon(Icons.eco, color: Color(0xFF8B9A76), size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // WIDGET KOTAK FORM KONTAK DARURAT
  Widget _buildContactCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Contact 1, Contact 2, dst + Tombol Hapus)
          if (_contacts.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact ${index + 1}',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                InkWell(
                  onTap: () => _removeContact(index),
                  child: const Icon(Icons.close, color: Colors.red),
                )
              ],
            ),
          if (_contacts.length > 1) const SizedBox(height: 16),

          // 1. CONTACT NAME
          _buildCustomLabel('Contact Name', '(required)', isRequired: true),
          TextFormField(
            controller: _contacts[index].nameController,
            decoration: _inputStyle('Full Name'),
            validator: (value) => value!.isEmpty ? 'Nama kontak wajib diisi' : null,
          ),
          const SizedBox(height: 20),

          // 2. RELATIONSHIP
          _buildCustomLabel('Relationship', '(dropdown)'),
          DropdownButtonFormField<String>(
            value: _contacts[index].relationship,
            decoration: _inputStyle('Select Relationship...'),
            icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
            items: _relationshipOptions.map((rel) {
              return DropdownMenuItem(value: rel, child: Text(rel));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _contacts[index].relationship = val;
              });
            },
            validator: (value) => value == null ? 'Pilih hubungan' : null,
          ),
          const SizedBox(height: 20),

          // 3. PHONE NUMBER
          _buildCustomLabel('Phone Number', ''),
          TextFormField(
            controller: _contacts[index].phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputStyle('812...').copyWith(
              // Bikin prefix +62 estetik sesuai mockup
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network('https://flagcdn.com/w20/id.png', width: 24), // Bendera Indo
                    const SizedBox(width: 8),
                    const Text('+62', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: Colors.grey.shade300), // Garis pembatas
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              suffixIcon: const Icon(Icons.check_circle, color: Colors.green), // Icon centang hijau mockup
            ),
            validator: (value) => value!.isEmpty ? 'Nomor HP wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  // Helper buat styling border textfield biar seragam
  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }
}