// lib/utils/file_helper.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Menyalin file dari path sumber (sementara) ke direktori dokumen aplikasi (permanen).
/// Mengembalikan path baru yang permanen.
Future<String> saveFileLocally(File sourceFile) async {
  // 1. Dapatkan direktori dokumen aplikasi
  final appDir = await getApplicationDocumentsDirectory();

  // 2. Buat nama file yang unik (bisa menggunakan nama file aslinya)
  final fileName = p.basename(sourceFile.path);

  // 3. Buat path tujuan yang permanen
  final permanentPath = '${appDir.path}/$fileName';

  // 4. Salin file dari sumber ke tujuan
  final savedFile = await sourceFile.copy(permanentPath);

  // 5. Kembalikan path baru yang sudah permanen
  return savedFile.path;
}