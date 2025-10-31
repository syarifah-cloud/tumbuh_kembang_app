// lib/models/diary_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String? id;
  final String userId;
  final String childProfileId;
  final DateTime date;
  final String mood;
  final String story;
  final String? audioPath;
  final String? imagePath; // <-- TAMBAHKAN FIELD INI

  DiaryEntry({
    this.id,
    required this.userId,
    required this.childProfileId,
    required this.date,
    required this.mood,
    required this.story,
    this.audioPath,
    this.imagePath, // <-- TAMBAHKAN DI CONSTRUCTOR
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'childProfileId': childProfileId,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'story': story,
      'audioPath': audioPath,
      'imagePath': imagePath, // <-- TAMBAHKAN SAAT MENGIRIM KE FIRESTORE
    };
  }

  factory DiaryEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DiaryEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      childProfileId: data['childProfileId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] ?? '',
      story: data['story'] ?? '',
      audioPath: data['audioPath'],
      imagePath: data['imagePath'], // <-- TAMBAHKAN SAAT MEMBACA DARI FIRESTORE
    );
  }
}