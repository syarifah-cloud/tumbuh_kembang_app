import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true; // Mulai dengan loading untuk fetch data
  UserProfile? _userProfile;

  // Controllers untuk form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Untuk mengubah password
  String _gender = 'Laki-laki';
  File? _image; // Untuk gambar baru yang dipilih
  String? _existingPhotoPath; // Untuk path gambar yang sudah ada

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat data profil dari Firestore
  Future<void> _loadUserProfile() async {
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (docSnapshot.exists) {
        _userProfile = UserProfile.fromFirestore(docSnapshot);
        // Isi form dengan data yang ada
        _nameController.text = _userProfile!.name;
        _emailController.text = _userProfile!.email;
        _gender = _userProfile!.gender;
        _existingPhotoPath = _userProfile!.photoPath;
      } else {
        // Jika dokumen belum ada, isi email dari Auth
        _emailController.text = currentUser!.email ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  // Fungsi untuk menyimpan perubahan
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Simpan foto baru ke penyimpanan lokal (jika ada)
      String? finalPhotoPath = _existingPhotoPath;
      if (_image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_image!.path);
        final savedImage = await _image!.copy('${appDir.path}/$fileName');
        finalPhotoPath = savedImage.path;
      }

      // 2. Buat objek UserProfile baru dengan data dari form
      final updatedProfile = UserProfile(
        uid: currentUser!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        photoPath: finalPhotoPath,
      );

      // 3. Simpan (atau perbarui) data ke Firestore
      //    Menggunakan .set() dengan merge:true adalah cara aman untuk membuat/memperbarui
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(updatedProfile.toFirestore(), SetOptions(merge: true));

      // 4. (Opsional) Perbarui password di Firebase Auth jika diisi
      if (_passwordController.text.isNotEmpty) {
        await currentUser!.updatePassword(_passwordController.text.trim());
        _passwordController.clear(); // Kosongkan field setelah berhasil
      }

      // 5. (Opsional) Perbarui nama di Firebase Auth
      if(currentUser!.displayName != updatedProfile.name) {
        await currentUser!.updateDisplayName(updatedProfile.name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    if (_image != null) {
      backgroundImage = FileImage(_image!);
    } else if (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty) {
      backgroundImage = FileImage(File(_existingPhotoPath!));
    }
    
    return Scaffold(
      // AppBar tidak diperlukan jika ini bagian dari BottomNavigationBar
      // appBar: AppBar(title: const Text('Lengkapi Profil Anda')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Lengkapi Profil Anda',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: backgroundImage,
                            child: backgroundImage == null 
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
                              : null,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Unggah Foto Anda',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap Orang Tua',
                      hint: 'Masukkan Nama Lengkap Ayah/Ibu',
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Masukkan Email Ayah/Ibu',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // Email tidak boleh diubah
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      hint: 'Kosongkan jika tidak ingin mengubah',
                      obscureText: true,
                      isRequired: false, // Tidak wajib diisi
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jenis Kelamin', style: TextStyle(color: Colors.grey)),
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
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Simpan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget helper untuk text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isRequired = true,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              // Menggunakan UnderlineInputBorder untuk mencocokkan desain
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return '$label tidak boleh kosong';
              }
              if (label.toLowerCase() == 'email' && !RegExp(r'\S+@\S+\.\S+').hasMatch(value!)) {
                return 'Format email tidak valid';
              }
              if (label.toLowerCase() == 'kata sandi' && value!.isNotEmpty && value.length < 6) {
                return 'Kata sandi minimal 6 karakter';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}