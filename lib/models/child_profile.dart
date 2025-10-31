import 'package:cloud_firestore/cloud_firestore.dart';

class ChildProfile {
  String? id;
  final String userId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String city; 
  final String? photoPath; // --- PERUBAHAN: dari photoUrl menjadi photoPath
  final bool isPremature;
  final double birthWeight;
  final double birthHeight;
  final double headCircumference;
  final String bloodType;
  final bool hasAllergy;
  final String foodAllergies;
  final String medicineAllergies;
  final String animalAllergies;
  final String otherAllergies;

  ChildProfile({
    this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.city,
    this.photoPath, // --- PERUBAHAN ---
    required this.isPremature,
    required this.birthWeight,
    required this.birthHeight,
    required this.headCircumference,
    required this.bloodType,
    required this.hasAllergy,
    required this.foodAllergies,
    required this.medicineAllergies,
    required this.animalAllergies,
    required this.otherAllergies,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'city': city,
      'photoPath': photoPath, // --- PERUBAHAN ---
      'isPremature': isPremature,
      'birthWeight': birthWeight,
      'birthHeight': birthHeight,
      'headCircumference': headCircumference,
      'bloodType': bloodType,
      'hasAllergy': hasAllergy,
      'foodAllergies': foodAllergies,
      'medicineAllergies': medicineAllergies,
      'animalAllergies': animalAllergies,
      'otherAllergies': otherAllergies,
    };
  }

  factory ChildProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChildProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: data['gender'] ?? 'Laki-laki',
      city: data['city'] ?? '',
      photoPath: data['photoPath'], // --- PERUBAHAN ---
      isPremature: data['isPremature'] ?? false,
      birthWeight: (data['birthWeight'] as num?)?.toDouble() ?? 0.0,
      birthHeight: (data['birthHeight'] as num?)?.toDouble() ?? 0.0,
      headCircumference: (data['headCircumference'] as num?)?.toDouble() ?? 0.0,
      bloodType: data['bloodType'] ?? 'Tidak Tahu',
      hasAllergy: data['hasAllergy'] ?? false,
      foodAllergies: data['foodAllergies'] ?? '',
      medicineAllergies: data['medicineAllergies'] ?? '',
      animalAllergies: data['animalAllergies'] ?? '',
      otherAllergies: data['otherAllergies'] ?? '',
    );
  }
}