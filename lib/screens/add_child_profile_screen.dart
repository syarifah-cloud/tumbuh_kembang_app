import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// --- PERBAIKAN IMPORT ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


const List<String> provinces = [
  'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Kepulauan Riau',
  'Jambi', 'Sumatera Selatan', 'Bangka Belitung', 'Bengkulu', 'Lampung',
  'DKI Jakarta', 'Jawa Barat', 'Banten', 'Jawa Tengah', 'DI Yogyakarta',
  'Jawa Timur', 'Bali', 'Nusa Tenggara Barat', 'Nusa Tenggara Timur',
  'Kalimantan Barat', 'Kalimantan Tengah', 'Kalimantan Selatan',
  'Kalimantan Timur', 'Kalimantan Utara', 'Sulawesi Utara', 'Gorontalo',
  'Sulawesi Tengah', 'Sulawesi Barat', 'Sulawesi Selatan', 'Sulawesi Tenggara',
  'Maluku', 'Maluku Utara', 'Papua', 'Papua Barat', 'Papua Selatan',
  'Papua Tengah', 'Papua Pegunungan', 'Papua Barat Daya',
];


class AddChildProfileScreen extends StatefulWidget {
  final ChildProfile? existingProfile;
  const AddChildProfileScreen({super.key, this.existingProfile});

  @override
  State<AddChildProfileScreen> createState() => _AddChildProfileScreenState();
}

class _AddChildProfileScreenState extends State<AddChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  File? _image;
  String? _existingPhotoPath;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDate;
  String _gender = 'Perempuan'; 

  String? _selectedProvince = 'Sumatera Barat';
  final _streetNameController = TextEditingController(text: 'Jl. Subang');
  final _blockNumberController = TextEditingController(text: 'No. 9');
  final _rtController = TextEditingController(text: '007');
  final _rwController = TextEditingController(text: '003');

  bool _isPremature = false;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headController = TextEditingController();
  String? _selectedBloodType;

  bool _hasAllergy = false;
  final _foodAllergyController = TextEditingController();
  final _medAllergyController = TextEditingController();
  final _animalAllergyController = TextEditingController();
  final _otherAllergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _existingPhotoPath = profile.photoPath; 
      
      _nameController.text = profile.name;
      _selectedDate = profile.dateOfBirth;
      _dobController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(profile.dateOfBirth);
      _gender = profile.gender;
      _isPremature = profile.isPremature;
      _weightController.text = profile.birthWeight > 0 ? profile.birthWeight.toString().replaceAll('.', ',') : '';
      _heightController.text = profile.birthHeight > 0 ? profile.birthHeight.toString().replaceAll('.', ',') : '';
      _headController.text = profile.headCircumference > 0 ? profile.headCircumference.toString().replaceAll('.', ',') : '';
      _selectedBloodType = profile.bloodType == 'Tidak Tahu' ? null : profile.bloodType;
      _hasAllergy = profile.hasAllergy;
      _foodAllergyController.text = profile.foodAllergies;
      _medAllergyController.text = profile.medicineAllergies;
      _animalAllergyController.text = profile.animalAllergies;
      _otherAllergyController.text = profile.otherAllergies;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _streetNameController.dispose();
    _blockNumberController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headController.dispose();
    _foodAllergyController.dispose();
    _medAllergyController.dispose();
    _animalAllergyController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // --- PERBAIKAN: MENAMBAHKAN KEMBALI FUNGSI YANG HILANG ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
        _formKey.currentState?.validate();
      });
    }
  }
  
  void _onProvinceChanged(String? newValue) {
    setState(() {
      _selectedProvince = newValue;
    });
  }
  // -----------------------------------------------------------

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data yang wajib diisi')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() { _isLoading = true; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda harus login untuk menyimpan profil.')));
      setState(() { _isLoading = false; });
      return;
    }
    
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String? finalPhotoPath = _existingPhotoPath;
      if (_image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_image!.path);
        final savedImage = await _image!.copy('${appDir.path}/$fileName');
        finalPhotoPath = savedImage.path;
      }

      List<String> addressParts = [];
      if (_streetNameController.text.isNotEmpty) addressParts.add(_streetNameController.text);
      if (_blockNumberController.text.isNotEmpty) addressParts.add('Blok/No. ${_blockNumberController.text}');
      if (_rtController.text.isNotEmpty && _rwController.text.isNotEmpty) addressParts.add('RT ${_rtController.text}/RW ${_rwController.text}');
      if (_selectedProvince != null) addressParts.add(_selectedProvince!);
      String fullAddress = addressParts.join(', ');

      final profileData = ChildProfile(
        id: widget.existingProfile?.id,
        userId: user.uid,
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDate!,
        gender: _gender,
        city: fullAddress,
        photoPath: finalPhotoPath,
        isPremature: _isPremature,
        birthWeight: double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0,
        birthHeight: double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0,
        headCircumference: double.tryParse(_headController.text.replaceAll(',', '.')) ?? 0.0,
        bloodType: _selectedBloodType ?? 'Tidak Tahu',
        hasAllergy: _hasAllergy,
        foodAllergies: _foodAllergyController.text.trim(),
        medicineAllergies: _medAllergyController.text.trim(),
        animalAllergies: _animalAllergyController.text.trim(),
        otherAllergies: _otherAllergyController.text.trim(),
      );

      final collection = FirebaseFirestore.instance.collection('child_profiles');
      
      if (widget.existingProfile == null) {
        await collection.add(profileData.toFirestore());
      } else {
        await collection.doc(profileData.id).update(profileData.toFirestore());
      }
      
      messenger.showSnackBar(SnackBar(content: Text('Profil ${profileData.name} berhasil disimpan!')));
      navigator.pop(profileData);

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... sisanya sama seperti kode sebelumnya
    final isEditing = widget.existingProfile != null;
    
    ImageProvider? backgroundImage;
    if (_image != null) {
      backgroundImage = FileImage(_image!);
    } else if (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty) {
      backgroundImage = FileImage(File(_existingPhotoPath!));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Profil Anak' : 'Tambah Profil Anak')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null
                            ? Icon(Icons.camera_alt, color: Colors.grey[800], size: 40)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      const Text('Unggah Foto', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 24),
              _buildTextField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  hint: 'Masukkan Nama Lengkap Anak'),
              _buildDateField(
                  label: 'Tanggal Lahir',
                  controller: _dobController,
                  hint: 'Pilih Tanggal Lahir'),
              _buildSectionTitle('Jenis Kelamin'),
               Row(
                children: [
                  Radio<String>(
                      value: 'Laki-laki',
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v!)),
                  const Text('Laki-laki'),
                  const SizedBox(width: 20),
                  Radio<String>(
                      value: 'Perempuan',
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v!)),
                  const Text('Perempuan'),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Alamat'),
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                hint: const Text('Pilih Provinsi'),
                isExpanded: true,
                items: provinces.map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: _onProvinceChanged, // Panggil fungsi yang benar
                validator: (value) =>
                    value == null && _streetNameController.text.isNotEmpty ? 'Provinsi tidak boleh kosong' : null,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                      label: 'Nama Jalan',
                      controller: _streetNameController,
                      hint: 'Contoh: Jl. Merdeka',
                      isRequired: false,
                    ),
              _buildTextField(
                      label: 'Blok / Nomor Jalan (Opsional)',
                      controller: _blockNumberController,
                      hint: 'Contoh: Blok C1 No. 5',
                      isRequired: false,
                    ),
              Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'RT',
                            controller: _rtController,
                            hint: '001',
                            keyboardType: TextInputType.number,
                             isRequired: false,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'RW',
                            controller: _rwController,
                            hint: '005',
                            keyboardType: TextInputType.number,
                             isRequired: false,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ],
                    ),
            _buildSectionTitle('Apakah anak Anda lahir prematur?'),
              Row(
                children: [
                  Radio<bool>(
                      value: true,
                      groupValue: _isPremature,
                      onChanged: (v) => setState(() => _isPremature = v!)),
                  const Text('Iya'),
                  const SizedBox(width: 20),
                  Radio<bool>(
                      value: false,
                      groupValue: _isPremature,
                      onChanged: (v) => setState(() => _isPremature = v!)),
                  const Text('Tidak'),
                ],
              ),
              _buildTextField(
                label: 'Berat badan saat lahir (kg)',
                controller: _weightController,
                hint: 'Contoh: 3,2',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    isRequired: false,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
                ],
              ),
              _buildTextField(
                label: 'Tinggi badan saat lahir (cm)',
                controller: _heightController,
                hint: 'Contoh: 50,5',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    isRequired: false,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
                ],
              ),
              _buildTextField(
                label: 'Lingkar kepala saat lahir (cm)',
                controller: _headController,
                hint: 'Contoh: 34',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    isRequired: false,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
                ],
              ),
              _buildSectionTitle('Golongan Darah'),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                hint: const Text('Pilih Golongan Darah (Opsional)'),
                isExpanded: true,
                items: ['A', 'B', 'AB', 'O'].map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedBloodType = newValue),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Adakah Riwayat Alergi?'),
              Row(
                children: [
                  Radio<bool>(
                      value: true,
                      groupValue: _hasAllergy,
                      onChanged: (v) => setState(() => _hasAllergy = v!)),
                  const Text('Ada'),
                  const SizedBox(width: 20),
                  Radio<bool>(
                      value: false,
                      groupValue: _hasAllergy,
                      onChanged: (v) => setState(() => _hasAllergy = v!)),
                  const Text('Tidak'),
                ],
              ),
              Visibility(
                visible: _hasAllergy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Alergi Makanan',
                        controller: _foodAllergyController,
                        hint: 'Contoh: udang, telur (pisahkan dengan koma)',
                        isRequired: false),
                    _buildTextField(
                        label: 'Alergi Obat-obatan',
                        controller: _medAllergyController,
                        hint: 'Contoh: penisilin',
                        isRequired: false),
                    _buildTextField(
                        label: 'Alergi Binatang',
                        controller: _animalAllergyController,
                        hint: 'Contoh: bulu kucing',
                        isRequired: false),
                    _buildTextField(
                        label: 'Alergi Lainnya',
                        controller: _otherAllergyController,
                        hint: 'Contoh: debu',
                        isRequired: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
            : Text(isEditing ? 'Simpan Perubahan' : 'Simpan Profil Anak', style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
  
  // --- PERBAIKAN: MENAMBAHKAN KEMBALI FUNGSI HELPER YANG HILANG ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return '$label tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

   Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required String hint
   }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onTap: () => _selectDate(context), // Panggil fungsi yang benar
            validator: (value) {
              if (_selectedDate == null) {
                return 'Tanggal Lahir tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}