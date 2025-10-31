import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';

// Model ParentProfile tidak berubah
class ParentProfile {
  final File? photo;
  final String name;
  final String email;
  final String gender;
  final String password;

  ParentProfile({
    this.photo,
    required this.name,
    required this.email,
    required this.gender,
    required this.password,
  });
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _image;
  String? _selectedGender;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    // --- PERBAIKAN 1: Tambahkan kurung kurawal {} ---
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih jenis kelamin.')),
        );
        return;
      }

      final profileData = ParentProfile(
        photo: _image,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        gender: _selectedGender!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Profil ${profileData.name} berhasil disimpan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lengkapi Profil Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoUploader(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'Nama Lengkap Orang Tua',
                          hint: 'Masukkan Nama Lengkap Ayah/Ibu',
                          controller: _nameController,
                        ),
                        _buildTextField(
                          label: 'Email',
                          hint: 'Masukkan Email Ayah/Ibu',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          label: 'Kata Sandi',
                          hint: 'Masukkan Kata Sandi Anda',
                          controller: _passwordController,
                          obscureText: true,
                        ),
                        const Text('Jenis Kelamin',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Row(
                          children: [
                            _buildGenderRadio('Laki-laki'),
                            _buildGenderRadio('Perempuan'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploader() {
    return GestureDetector(
      onTap: _pickImage,
      child: Row(
        children: [
          DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(50),
            color: Colors.blue,
            strokeWidth: 1,
            dashPattern: const [6, 6],
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.withAlpha(13),
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null
                  ? const Icon(Icons.camera_alt_outlined,
                      color: Colors.blue, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Unggah Foto Anda',
            style: TextStyle(
                color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator ??
                (value) {
                  // --- PERBAIKAN 2: Tambahkan kurung kurawal {} ---
                  if (value == null || value.isEmpty) {
                    return '$label tidak boleh kosong';
                  }
                  return null;
                },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue)),
              contentPadding: const EdgeInsets.only(top: 10, bottom: 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRadio(String title) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(title),
        value: title,
        groupValue: _selectedGender,
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        activeColor: Colors.blue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
