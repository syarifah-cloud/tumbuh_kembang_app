// lib/screens/diary_screen.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../models/child_profile.dart';
import '../models/diary_entry.dart';
import '../utils/file_helper.dart';
import './diary_detail_screen.dart';

class Mood {
  final String emoji;
  final String name;
  const Mood({required this.emoji, required this.name});
}

class DiaryScreen extends StatefulWidget {
  final ChildProfile childProfile;
  const DiaryScreen({super.key, required this.childProfile});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // --- State Management ---
  DateTime _selectedDate = DateTime.now();
  String? _selectedMoodName;
  final _storyController = TextEditingController();
  bool _isLoading = false;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  String? _recordedFilePath;
  String? _selectedImagePath;

  final List<Mood> _moods = const [
    Mood(emoji: '😊', name: 'Happy'), Mood(emoji: '😔', name: 'Sad'),
    Mood(emoji: '😠', name: 'Irritated'), Mood(emoji: '🥳', name: 'Energetic'),
  ];

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
  }

  @override
  void dispose() {
    _storyController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _selectedImagePath = pickedFile.path);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memilih gambar: $e")));
    }
  }
  
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin mikrofon diperlukan.')));
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/diary_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RecordingDialog(recorder: _recorder),
      ).then((path) {
        if (path is String && path.isNotEmpty) {
          setState(() => _recordedFilePath = path);
        }
      });
    }
  }

  // Letakkan di dalam class _DiaryScreenState

  Future<void> _deleteDiaryEntry(DiaryEntry entry) async {
    // Pastikan ID entri tidak null
    if (entry.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID entri tidak ditemukan.')),
      );
      return;
    }

    try {
      // 1. Hapus file lokal (gambar dan audio) jika ada
      if (entry.imagePath != null && entry.imagePath!.isNotEmpty) {
        final imageFile = File(entry.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
      if (entry.audioPath != null && entry.audioPath!.isNotEmpty) {
        final audioFile = File(entry.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      // 2. Hapus dokumen dari Firestore
      await FirebaseFirestore.instance
          .collection('diary_entries')
          .doc(entry.id)
          .delete();

      // 3. Beri feedback ke pengguna
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cerita berhasil dihapus.')),
      );

    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus cerita: $e')),
      );
    }
  }

  Future<void> _postNewEntry() async {
    final text = _storyController.text.trim();
    final moodName = _selectedMoodName;
    final user = FirebaseAuth.instance.currentUser;

    if (text.isEmpty || moodName == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi mood dan cerita.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? permanentAudioPath;
      if (_recordedFilePath != null) {
        permanentAudioPath = await saveFileLocally(File(_recordedFilePath!));
      }
      String? permanentImagePath;
      if (_selectedImagePath != null) {
        permanentImagePath = await saveFileLocally(File(_selectedImagePath!));
      }

      final newEntry = DiaryEntry(
        userId: user.uid,
        childProfileId: widget.childProfile.id!,
        date: _selectedDate,
        mood: moodName,
        story: text,
        audioPath: permanentAudioPath,
        imagePath: permanentImagePath,
      );

      await FirebaseFirestore.instance.collection('diary_entries').add(newEntry.toFirestore());

      setState(() {
        _storyController.clear();
        _selectedMoodName = null;
        _recordedFilePath = null;
        _selectedImagePath = null;
        _selectedDate = DateTime.now();
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cerita berhasil diposting!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memposting: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Diary Harian', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFF0F4F7),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMoodSelector(),
            const SizedBox(height: 20),
            _buildStoryInput(),
            const SizedBox(height: 20),
            _buildPostingButton(),
            const SizedBox(height: 30),
            _buildDiaryHistoryList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bagaimana mood Anak hari ini?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moods.map((mood) => _buildMoodChip(mood)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(Mood mood) {
    final bool isSelected = _selectedMoodName == mood.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedMoodName = mood.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2.0),
        ),
        child: Column(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(mood.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoryInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ceritakan kegiatan Anakmu hari ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextField(controller: _storyController, maxLines: 5, decoration: const InputDecoration(hintText: 'Ketik di sini...', border: InputBorder.none)),
          if (_selectedImagePath != null) _buildImagePreview(),
          if (_recordedFilePath != null) _buildAudioPreview(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), tooltip: 'Tambah Gambar', onPressed: _showImagePickerOptions),
              IconButton(icon: const Icon(Icons.mic, color: Colors.blue), tooltip: 'Rekam Suara', onPressed: _startRecording),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_selectedImagePath!), height: 100, fit: BoxFit.cover)),
          Positioned(
            top: -10,
            right: -10,
            // DIPERBAIKI: Menghapus parameter 'shadowColor' yang tidak ada di Icon.
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)]),
              onPressed: () => setState(() => _selectedImagePath = null),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAudioPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audiotrack, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text("Rekaman audio siap."),
            const Spacer(),
            IconButton(icon: Icon(Icons.delete, color: Colors.red.shade400), onPressed: () => setState(() => _recordedFilePath = null)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostingButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _postNewEntry,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
          : const Text('Posting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
  
  // GANTI SELURUH FUNGSI INI DI diary_screen.dart

  Widget _buildDiaryHistoryList() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text("Pengguna tidak terautentikasi."));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('History Cerita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('diary_entries')
                .where('userId', isEqualTo: currentUserId)
                .where('childProfileId', isEqualTo: widget.childProfile.id)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Belum ada cerita yang tersimpan.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final entries = snapshot.data!.docs
                  .map((doc) => DiaryEntry.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  
                  // ================== PERUBAHAN UTAMA DI SINI ==================
                  return Dismissible(
                    // Key unik untuk setiap item, penting agar Flutter tahu item mana yang dihapus
                    key: Key(entry.id!),
                    
                    // Widget yang muncul di belakang saat item digeser
                    background: Container(
                      color: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    
                    // Arah geser yang diizinkan (dari kanan ke kiri)
                    direction: DismissDirection.endToStart,
                    
                    // Fungsi konfirmasi sebelum item benar-benar dihapus
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Konfirmasi Hapus"),
                            content: const Text("Apakah Anda yakin ingin menghapus cerita ini? Tindakan ini tidak dapat diurungkan."),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false), // Jangan hapus
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () {
                                  // Panggil fungsi hapus kita di sini!
                                  _deleteDiaryEntry(entry);
                                  Navigator.of(context).pop(true); // Ya, hapus item dari list
                                },
                                child: const Text("Hapus"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    
                    // Widget asli yang ditampilkan
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryDetailScreen(entry: entry)));
                      },
                      child: _buildDiaryEntryItem(entry),
                    ),
                  );
                  // ==========================================================
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryEntryItem(DiaryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Text(
              _moods.firstWhere((m) => m.name == entry.mood, orElse: () => const Mood(emoji: '?', name: '')).emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(entry.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(entry.story, maxLines: 2, overflow: TextOverflow.ellipsis), // MaxLines 2
                ],
              ),
            ),
            if (entry.audioPath != null) const Icon(Icons.graphic_eq, color: Colors.blue),
            if (entry.imagePath != null) const Icon(Icons.image, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

// Widget Dialog untuk Merekam (TETAP SAMA)
// Widget Dialog untuk Poin #2
class RecordingDialog extends StatefulWidget {
  final FlutterSoundRecorder recorder;
  const RecordingDialog({super.key, required this.recorder});

  @override
  State<RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<RecordingDialog> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) => d.toString().split('.').first.padLeft(8, "0");

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Merekam Suara..."),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 64),
          const SizedBox(height: 20),
          Text(_formatDuration(_duration), style: const TextStyle(fontSize: 24, fontFamily: 'monospace')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.recorder.stopRecorder();
            Navigator.of(context).pop(true); // Tutup dialog tanpa mengembalikan path
          },
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            final path = await widget.recorder.stopRecorder();
            Navigator.of(context).pop(path); // Tutup dialog dan kembalikan path file
          },
          child: const Text("Selesai"),
        ),
      ],
    );
  }
}