// lib/screens/diary_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart'; // Sesuaikan path ini

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_isPlayerInitialized || widget.entry.audioPath == null) return;

    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() => _isPlaying = false);
    } else {
      await _player.startPlayer(
        fromURI: widget.entry.audioPath,
        whenFinished: () => setState(() => _isPlaying = false),
      );
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mapping mood name ke emoji
    final Map<String, String> moodEmojis = {
      'Happy': '😊', 'Sad': '😔', 'Irritated': '😠', 'Energetic': '🥳'
    };
    final emoji = moodEmojis[widget.entry.mood] ?? '🤔';

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('d MMMM yyyy').format(widget.entry.date)),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Mood dan Tanggal
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.mood,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.entry.date),
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),

            // Tampilkan Gambar jika ada
            if (widget.entry.imagePath != null && widget.entry.imagePath!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Foto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(widget.entry.imagePath!)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            
            // Cerita
            const Text("Cerita Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              widget.entry.story,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            // Audio Player jika ada
            if (widget.entry.audioPath != null && widget.entry.audioPath!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Rekaman Suara", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade200,
                       borderRadius: BorderRadius.circular(30)
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: Icon(_isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline, size: 32, color: Colors.blue.shade800),
                           onPressed: _togglePlay,
                         ),
                         const Text("Putar"),
                       ],
                     ),
                   )
                ],
              )
          ],
        ),
      ),
    );
  }
}