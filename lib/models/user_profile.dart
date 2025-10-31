import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid; // ID dari Firebase Auth, sebagai ID dokumen
  final String name;
  final String email;
  final String gender;
  final String? photoPath; // Path foto lokal, sama seperti profil anak

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.gender,
    this.photoPath,
  });

  // Konversi objek UserProfile menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'photoPath': photoPath,
      // 'uid' tidak perlu disimpan di dalam field karena sudah menjadi ID dokumen
    };
  }

  // Membuat objek UserProfile dari dokumen Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? 'Laki-laki',
      photoPath: data['photoPath'],
    );
  }
}