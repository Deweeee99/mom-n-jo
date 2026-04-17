  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';

  class AddProfileMedicalScreen extends StatefulWidget {
    final Map<String, dynamic>? previousData; // Nampung data dari layar 1 & 2

    const AddProfileMedicalScreen({super.key, this.previousData});

    @override
    State<AddProfileMedicalScreen> createState() => _AddProfileMedicalScreenState();
  }

  class _AddProfileMedicalScreenState extends State<AddProfileMedicalScreen> {
    // Tema Warna Sesuai Mockup
    final Color _primaryColor = const Color(0xFF693D2C); // Coklat Tua
    final Color _bgColor = const Color(0xFFFDF8F4); // Peach Background
    final Color _btnDarkColor = const Color(0xFF4A2E20); // Coklat Gelap
    final Color _chipActiveColor = const Color(0xFFC48671); // Coklat Terang buat Chip

    bool _isSaving = false;

    // --- DATA KONDISI MEDIS (CHIPS) ---
    final List<String> _conditionsList = [
      'Allergies', 'Dermatitis', 'Eczema', 'Sensitive Skin',
      'Psoriasis', 'Claustrophobia', 'Osteoporosis', 'Rheumatism',
      'Recent Bone Fracture', 'Varicose Veins', 'Depression',
      'Heart Condition / Pacemaker', 'High / Low Blood Pressure',
      'Headaches / Migraine', 'Asthma / Respiratory', 'Constipation',
      'Stroke', 'Epilepsy', 'Diabetes', 'Cancer', 'Irritable Bowel Syndrome'
    ];
    final Set<String> _selectedConditions = {};
    final TextEditingController _othersConditionCtrl = TextEditingController();

    // --- DATA STATUS MEDIS (SWITCHES) ---
    bool _isMedication = false;
    final TextEditingController _medicationCtrl = TextEditingController();

    bool _isSportsInjury = false;
    final TextEditingController _sportsInjuryCtrl = TextEditingController();

    bool _isSurgery = false;
    final TextEditingController _surgeryCtrl = TextEditingController();

    bool _isPregnant = false;
    final TextEditingController _pregnantMonthsCtrl = TextEditingController();
    DateTime? _pregnantDueDate;

    @override
    void dispose() {
      _othersConditionCtrl.dispose();
      _medicationCtrl.dispose();
      _sportsInjuryCtrl.dispose();
      _surgeryCtrl.dispose();
      _pregnantMonthsCtrl.dispose();
      super.dispose();
    }

    // --- FUNGSI SAVE TERAKHIR ---
    Future<void> _onSaveProfile() async {
      setState(() => _isSaving = true);

      // Kumpulin semua data medis
      final medicalData = {
        'conditions': _selectedConditions.toList(),
        'other_condition': _othersConditionCtrl.text.trim(),
        'is_medication': _isMedication,
        'medication_details': _medicationCtrl.text.trim(),
        'is_sports_injury': _isSportsInjury,
        'sports_injury_details': _sportsInjuryCtrl.text.trim(),
        'is_surgery': _isSurgery,
        'surgery_details': _surgeryCtrl.text.trim(),
        'is_pregnant': _isPregnant,
        'pregnant_months': _pregnantMonthsCtrl.text.trim(),
        'pregnant_due_date': _pregnantDueDate?.toIso8601String(),
      };

      // Gabungin data layar 1, 2, dan 3
      final finalProfileData = {
        ...?widget.previousData,
        'medical_history': medicalData,
      };

      // Simulasi nembak API backend (loading 2 detik)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil ditambahkan!')),
      );

      // Balik ke halaman Profile Selection dan hapus tumpukan layar pendaftaran
      Navigator.pushNamedAndRemoveUntil(context, '/profile_selection', (route) => route.isFirst);
    }

    Future<void> _pickDueDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 1),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _primaryColor, 
                onPrimary: Colors.white, 
                onSurface: Colors.black87, 
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          _pregnantDueDate = picked;
        });
      }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER TEXT
                          Text(
                            'Medical History',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell us about your health condition',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 24),

                          // BAGIAN 1: CONDITIONS (CHIPS)
                          _buildSectionCard(
                            title: '1. Conditions',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: _conditionsList.map((condition) {
                                    final isSelected = _selectedConditions.contains(condition);
                                    return ChoiceChip(
                                      label: Text(condition),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedConditions.add(condition);
                                          } else {
                                            _selectedConditions.remove(condition);
                                          }
                                        });
                                      },
                                      selectedColor: _chipActiveColor,
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? _chipActiveColor : Colors.grey.shade300,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _othersConditionCtrl,
                                  decoration: _inputStyle('Others (please specify)'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // BAGIAN 2: MEDICAL STATUS (SWITCHES)
                          _buildSectionTitle('2. Medical Status'),
                          const SizedBox(height: 12),

                          // Status A: Medication
                          _buildStatusCard(
                            icon: Icons.medical_services_outlined,
                            title: 'Medication / Medical Supervision',
                            question: 'Are you under medication or medical supervision?',
                            value: _isMedication,
                            onChanged: (val) => setState(() => _isMedication = val),
                            conditionalField: _isMedication
                                ? TextFormField(
                                    controller: _medicationCtrl,
                                    decoration: _inputStyle('Please specify'),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Status B: Sports Injury
                          _buildStatusCard(
                            icon: Icons.directions_run,
                            title: 'Sports Injury',
                            question: 'Do you have any sport injuries?',
                            value: _isSportsInjury,
                            onChanged: (val) => setState(() => _isSportsInjury = val),
                            conditionalField: _isSportsInjury
                                ? TextFormField(
                                    controller: _sportsInjuryCtrl,
                                    decoration: _inputStyle('Describe injury and date'),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Status C: Surgery / Accident
                          _buildStatusCard(
                            icon: Icons.personal_injury_outlined,
                            title: 'Surgery / Accident',
                            question: 'Have you had recent surgery or accident?',
                            value: _isSurgery,
                            onChanged: (val) => setState(() => _isSurgery = val),
                            conditionalField: _isSurgery
                                ? TextFormField(
                                    controller: _surgeryCtrl,
                                    decoration: _inputStyle('Specify surgery/accident and date'),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Status D: Pregnancy
                          _buildStatusCard(
                            icon: Icons.pregnant_woman_outlined,
                            title: 'Pregnancy Status',
                            question: 'Are you pregnant or planning pregnancy?',
                            value: _isPregnant,
                            onChanged: (val) => setState(() => _isPregnant = val),
                            conditionalField: _isPregnant
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('How many months pregnant', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _pregnantMonthsCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputStyle('e.g. 5'),
                                      ),
                                      const SizedBox(height: 12),
                                      Text('Due date', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: _pickDueDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _pregnantDueDate == null
                                                    ? 'Select Due Date'
                                                    : DateFormat('dd MMM yyyy').format(_pregnantDueDate!),
                                                style: TextStyle(
                                                  color: _pregnantDueDate == null ? Colors.grey.shade500 : Colors.black87,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER TOMBOL BACK & SAVE
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
                            child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Tombol Save
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _onSaveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _btnDarkColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 4,
                            ),
                            child: _isSaving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Widget Header Title Section
    Widget _buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      );
    }

    // Widget Wrapper Card Section
    Widget _buildSectionCard({required String title, required Widget child}) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF6E6D9), // Coklat Pudar Background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Icon(Icons.keyboard_arrow_up, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
    }

    // Widget Card untuk Status (Toggle Switch)
    Widget _buildStatusCard({
      required IconData icon,
      required String title,
      required String question,
      required bool value,
      required ValueChanged<bool> onChanged,
      required Widget conditionalField,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9EAE1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  activeTrackColor: _chipActiveColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            
            // Efek Animasi turun kalau diklik YES
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: conditionalField,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    InputDecoration _inputStyle(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
      );
    }
  }