// lib/screens/register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import yang diperlukan untuk penyimpanan lokal
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import model UserProfile
import '../models/user_profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _gender = 'Laki-laki';
  File? _selectedImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // --- FUNGSI BARU UNTUK MENAMPILKAN PILIHAN KAMERA/GALERI ---
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI PICK IMAGE YANG SUDAH DIMODIFIKASI ---
  Future<void> _pickImageFromSource(ImageSource source) async {
    // Tutup bottom sheet terlebih dahulu
    Navigator.of(context).pop();

    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- FUNGSI REGISTER (TIDAK ADA PERUBAHAN DI SINI) ---
  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Buat user di Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('Gagal membuat user.');
      }

      // Update display name di Auth
      await user.updateDisplayName(_nameController.text.trim());

      // 2. Simpan foto ke penyimpanan LOKAL (jika ada)
      String? localPhotoPath;
      if (_selectedImage != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_selectedImage!.path);
        final savedImage =
            await _selectedImage!.copy('${appDir.path}/$fileName');
        localPhotoPath = savedImage.path;
      }

      // 3. Buat objek UserProfile dengan data yang benar
      final newUserProfile = UserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        photoPath: localPhotoPath, // Gunakan path lokal
      );

      // 4. Simpan data user ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(newUserProfile.toFirestore());

      // 5. Navigasi ke halaman utama setelah berhasil
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan.";
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mendaftar: ${e.toString()}')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil Anda'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- PERUBAHAN PADA onTap GESTURE DETECTOR ---
              GestureDetector(
                onTap: _showImageSourceActionSheet, // Panggil fungsi untuk menampilkan pilihan
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt,
                              color: Colors.blue, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unggah Foto Anda',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField('Nama Lengkap Orang Tua',
                  'Masukkan Nama Lengkap Ayah/Ibu', _nameController),
              _buildTextField('Email', 'Masukkan Email Ayah/Ibu',
                  _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('Password', 'Masukkan Password',
                  _passwordController,
                  obscureText: true),

              // Jenis Kelamin
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Jenis Kelamin',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildRadio('Laki-laki')),
                  Expanded(child: _buildRadio('Perempuan')),
                ],
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Simpan',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget tidak perlu diubah
  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Helper widget tidak perlu diubah
  Widget _buildRadio(String title) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: _gender,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _gender = val;
          });
        }
      },
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blue,
    );
  }
}