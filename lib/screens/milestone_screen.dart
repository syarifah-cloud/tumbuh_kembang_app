// File: lib/screens/milestone_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_final_project/models/child_profile.dart'; // Sesuaikan path jika perlu

// --- MODEL DATA (Tidak ada perubahan) ---
enum AnswerStatus { belum, sedangBelajar, sudahBisa }

class MilestoneQuestion {
  final String id;
  final String title;
  MilestoneQuestion({required this.id, required this.title});
}

class MilestoneCategory {
  final String title;
  final IconData icon;
  final Color iconBackgroundColor;
  final List<MilestoneQuestion> questions;
  bool isExpanded;

  MilestoneCategory({
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    required this.questions,
    this.isExpanded = false,
  });
}

class AgeStage {
  final String title;
  final List<MilestoneCategory> categories;
  AgeStage({required this.title, required this.categories});
}

// --- LAYAR UTAMA FITUR INI ---
class MilestoneScreen extends StatefulWidget {
  final ChildProfile childProfile;

  const MilestoneScreen({super.key, required this.childProfile});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> {
  // --- State Lokal ---
  int _currentStageIndex = 0;
  final Map<String, AnswerStatus> _answers = {};
  late final List<AgeStage> _ageStages;

  // --- State Baru untuk Integrasi Firestore ---
  bool _isLoading = true; // Untuk menampilkan loading indicator

  @override
  void initState() {
    super.initState();
    _ageStages = _getMilestoneData();
    if (_ageStages.isNotEmpty && _ageStages[0].categories.isNotEmpty) {
      _ageStages[0].categories[0].isExpanded = true;
    }
    // Panggil fungsi untuk memuat data jawaban dari Firestore
    _loadAnswersFromFirestore();
  }

  // --- FUNGSI-FUNGSI BARU UNTUK FIRESTORE ---

  Future<void> _loadAnswersFromFirestore() async {
    // Pastikan childProfile.id tidak null
    if (widget.childProfile.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('milestone_answers')
          .doc(widget.childProfile.id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!['answers'] as Map<String, dynamic>? ?? {};
        final loadedAnswers = <String, AnswerStatus>{};
        
        data.forEach((key, value) {
          final status = AnswerStatus.values.firstWhere(
            (e) => e.name == value,
            orElse: () => AnswerStatus.belum,
          );
          loadedAnswers[key] = status;
        });

        if (mounted) {
          setState(() {
            _answers.addAll(loadedAnswers);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data perkembangan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAnswerToFirestore(String questionId, AnswerStatus status) async {
    if (widget.childProfile.id == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('milestone_answers')
        .doc(widget.childProfile.id);

    try {
      await docRef.set({
        'childProfileId': widget.childProfile.id,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'answers': {
          questionId: status.name // Simpan enum sebagai string (e.g., "sudahBisa")
        }
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan data: $e")),
        );
      }
    }
  }

  // --- FUNGSI LOGIKA (Tidak ada perubahan) ---

  void _changeStage(int newIndex) {
    if (newIndex >= 0 && newIndex < _ageStages.length) {
      setState(() {
        for (var category in _ageStages[_currentStageIndex].categories) {
          category.isExpanded = false;
        }
        _currentStageIndex = newIndex;
        if (_ageStages[newIndex].categories.isNotEmpty) {
          _ageStages[newIndex].categories[0].isExpanded = true;
        }
      });
    }
  }

  int _calculateCompleted(MilestoneCategory category) {
    int completedCount = 0;
    for (var question in category.questions) {
      if (_answers[question.id] == AnswerStatus.sudahBisa) {
        completedCount++;
      }
    }
    return completedCount;
  }

  int _calculateTotalScore() {
    int totalScore = 0;
    _answers.forEach((key, value) {
      if (value == AnswerStatus.sudahBisa) {
        totalScore++;
      }
    });
    return totalScore;
  }

  void _showScoreDialog() {
    final totalScore = _calculateTotalScore();
    final bool isGoodScore = totalScore >= 3;
    final String dialogTitle = isGoodScore ? 'Tahapan Selesai!' : 'Yuk Semangat!';
    final String message = isGoodScore
        ? 'Selamat! Tahapan anak sudah bagus. Tetap semangat dalam mendampingi tumbuh kembang anak!'
        : 'Terus semangat Bunda! Jangan lupa berikan stimulus yang rutin untuk mendukung tumbuh kembang si kecil ❤';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda telah menyelesaikan $totalScore tahapan dengan status "Sudah Bisa".'),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN: Tampilkan loading indicator saat data dimuat ---
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tahapan Kembang')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentStage = _ageStages[_currentStageIndex];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Tahapan Kembang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDescriptionCard(),
            const SizedBox(height: 20),
            _buildAgeSelector(),
            const SizedBox(height: 20),
            _buildCategoryTiles(currentStage),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScoreDialog,
        label: const Text('Lihat Skor'),
        icon: const Icon(Icons.star),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
      child: const Text(
        'Milestones adalah tahapan seru dalam tumbuh kembang anak yang menandai setiap langkah ajaib mereka saat tumbuh besar! 🎉✨',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _currentStageIndex > 0 ? () => _changeStage(_currentStageIndex - 1) : null,
          ),
          Text(_ageStages[_currentStageIndex].title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _currentStageIndex < _ageStages.length - 1 ? () => _changeStage(_currentStageIndex + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTiles(AgeStage currentStage) {
    return Column(
      children: currentStage.categories.map((category) {
        int completed = _calculateCompleted(category);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            key: PageStorageKey(category.title + _currentStageIndex.toString()),
            initiallyExpanded: category.isExpanded,
            onExpansionChanged: (isExpanding) => setState(() => category.isExpanded = isExpanding),
            leading: CircleAvatar(backgroundColor: category.iconBackgroundColor, child: Icon(category.icon, color: Colors.white)),
            title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$completed/${category.questions.length} Completed'),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Column(
                  children: category.questions.map((question) => _buildQuestionItem(question)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionItem(MilestoneQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.pink[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            _buildRadioOption(title: 'Belum', value: AnswerStatus.belum, questionId: question.id),
            _buildRadioOption(title: 'Sedang belajar', value: AnswerStatus.sedangBelajar, questionId: question.id),
            _buildRadioOption(title: 'Sudah bisa', value: AnswerStatus.sudahBisa, questionId: question.id),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({required String title, required AnswerStatus value, required String questionId}) {
    return SizedBox(
      height: 36,
      child: RadioListTile<AnswerStatus>(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: _answers[questionId],
        // --- PERUBAHAN: Panggil fungsi save saat nilai berubah ---
        onChanged: (AnswerStatus? newValue) {
          if (newValue == null) return;
          
          // 1. Perbarui UI secara instan
          setState(() {
            _answers[questionId] = newValue;
          });
          
          // 2. Simpan perubahan ke Firestore di background
          _saveAnswerToFirestore(questionId, newValue);
        },
        contentPadding: EdgeInsets.zero,
        activeColor: Colors.blue,
      ),
    );
  }
}

// --- SUMBER DATA UTAMA (Tidak ada perubahan) ---
List<AgeStage> _getMilestoneData() {
  // ... (isi fungsi ini sama persis dengan kode lama Anda, tidak perlu disalin ulang jika sudah ada) ...
  // ... Cukup salin bagian ini jika Anda memulai dari file kosong ...
  return [
    // === TAHAP 0-3 BULAN ===
    AgeStage(
      title: '0-3 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '0-3-motorik-1', title: 'Mengangkat kepala 45 derajat'),
            MilestoneQuestion(id: '0-3-motorik-2', title: 'Menggerakkan kepala ke kanan/kiri'),
            MilestoneQuestion(id: '0-3-motorik-3', title: 'Membuka dan menutup jari'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '0-3-sensorik-1', title: 'Merespon suara keras, lembut atau sentuhan'),
            MilestoneQuestion(id: '0-3-sensorik-2', title: 'Gerakan mata mengikuti objek'),
            MilestoneQuestion(id: '0-3-sensorik-3', title: 'Melihat dan menatap wajah anda'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '0-3-komunikasi-1', title: 'Mulai membuat suara "aah" atau "ooh"'),
            MilestoneQuestion(id: '0-3-komunikasi-2', title: 'Tersenyum saat diajak bicara'),
            MilestoneQuestion(id: '0-3-komunikasi-3', title: 'Menangis untuk berkomunikasi'),
          ],
        ),
      ],
    ),

    // === TAHAP 4-6 BULAN ===
    AgeStage(
      title: '4-6 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '4-6-motorik-1', title: 'Berguling'),
            MilestoneQuestion(id: '4-6-motorik-2', title: 'Menyangga berat badan dengan kaki'),
            MilestoneQuestion(id: '4-6-motorik-3', title: 'Mulai belajar duduk dengan bantuan'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '4-6-sensorik-1', title: 'Meraih mainan dengan dua tangan'),
            MilestoneQuestion(id: '4-6-sensorik-2', title: 'Memasukkan benda ke mulut untuk eksplorasi'),
            MilestoneQuestion(id: '4-6-sensorik-3', title: 'Merespon perubahan nada suara'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '4-6-komunikasi-1', title: 'Tertawa dan  gembira'),
            MilestoneQuestion(id: '4-6-komunikasi-2', title: 'Mengoceh (babbling seperti "ba-ba-ba")'),
            MilestoneQuestion(id: '4-6-komunikasi-3', title: 'Menunjukkan kesukaan/ketidaksukaan dengan suara'),
          ],
        ),
      ],
    ),
    // === TAHAP 6-9 BULAN ===
    AgeStage(
      title: '6-9 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '6-9-motorik-1', title: 'Duduk sendiri tanpa bantuan'),
            MilestoneQuestion(id: '6-9-motorik-2', title: 'Mulai merambat untuk berdiri'),
            MilestoneQuestion(id: '6-9-motorik-3', title: 'Memindahkan benda dari satu tangan ke tangan lain'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '6-9-sensorik-1', title: 'Mencari benda yang disembunyikan'),
            MilestoneQuestion(id: '6-9-sensorik-2', title: 'Menjatuhkan dan mengambil benda berulang kali'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '6-9-komunikasi-1', title: 'Merespon saat namanya dipanggil'),
            MilestoneQuestion(id: '6-9-komunikasi-2', title: 'Meniru suara dan gestur sederhana'),
          ],
        ),
      ],
    ),

    // === TAHAP 9-12 BULAN ===
    AgeStage(
      title: '9-12 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '9-12-motorik-1', title: 'Berjalan sambil berpegangan (merambat)'),
            MilestoneQuestion(id: '9-12-motorik-2', title: 'Mengambil benda kecil dengan ibu jari & telunjuk'),
            MilestoneQuestion(id: '9-12-motorik-3', title: 'Berdiri sendiri selama beberapa detik'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '9-12-sensorik-1', title: 'Menunjuk benda yang diinginkan'),
            MilestoneQuestion(id: '9-12-sensorik-2', title: 'Menikmati permainan "cilukba"'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '9-12-komunikasi-1', title: 'Mengucapkan "mama" atau "dada" dengan arti'),
            MilestoneQuestion(id: '9-12-komunikasi-2', title: 'Memahami perintah sederhana seperti "tidak"'),
            MilestoneQuestion(id: '9-12-komunikasi-3', title: 'Melambaikan tangan (dadah)'),
          ],
        ),
      ],
    ),

    // === TAHAP 12-18 BULAN ===
    AgeStage(
      title: '12-18 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '12-18-motorik-1', title: 'Berjalan sendiri tanpa bantuan'),
            MilestoneQuestion(id: '12-18-motorik-2', title: 'Mencoret-coret dengan krayon atau pensil'),
            MilestoneQuestion(id: '12-18-motorik-3', title: 'Minum sendiri dari cangkir'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '12-18-sensorik-1', title: 'Mengenali bagian tubuh (misal: hidung, mata)'),
            MilestoneQuestion(id: '12-18-sensorik-2', title: 'Membangun menara dari 2-3 balok'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '12-18-komunikasi-1', title: 'Mengucapkan beberapa kata tunggal'),
            MilestoneQuestion(id: '12-18-komunikasi-2', title: 'Mengikuti perintah satu langkah ("Ambil bola")'),
            MilestoneQuestion(id: '12-18-komunikasi-3', title: 'Menunjuk gambar di buku saat ditanya'),
          ],
        ),
      ],
    ),

    // === TAHAP 18-24 BULAN ===
    AgeStage(
      title: '18-24 Bulan',
      categories: [
        MilestoneCategory(
          title: 'Tahapan Motorik',
          icon: Icons.run_circle_outlined,
          iconBackgroundColor: Colors.pink.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '18-24-motorik-1', title: 'Berlari dengan cukup stabil'),
            MilestoneQuestion(id: '18-24-motorik-2', title: 'Menendang bola ke depan'),
            MilestoneQuestion(id: '18-24-motorik-3', title: 'Naik turun tangga dengan bantuan'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Sensorik',
          icon: Icons.visibility_outlined,
          iconBackgroundColor: Colors.green.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '18-24-sensorik-1', title: 'Mulai menyortir bentuk dan warna'),
            MilestoneQuestion(id: '18-24-sensorik-2', title: 'Terlibat dalam permainan pura-pura (pretend play)'),
          ],
        ),
        MilestoneCategory(
          title: 'Tahapan Komunikasi',
          icon: Icons.chat_bubble_outline,
          iconBackgroundColor: Colors.purple.withAlpha(128),
          questions: [
            MilestoneQuestion(id: '18-24-komunikasi-1', title: 'Menggabungkan 2 kata menjadi frasa ("mau susu")'),
            MilestoneQuestion(id: '18-24-komunikasi-2', title: 'Mengenal nama benda-benda umum di sekitar'),
            MilestoneQuestion(id: '18-24-komunikasi-3', title: 'Mengikuti perintah dua langkah'),
          ],
        ),
      ],
    ),
  ];
}
