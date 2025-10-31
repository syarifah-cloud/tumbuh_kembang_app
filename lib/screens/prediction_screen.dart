// lib/prediction_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// DATA MODEL UNTUK MENAMPILKAN HASIL
class ResultData {
  final String title;
  final String description;
  final Color color;
  final List<String> recommendations;

  ResultData({
    required this.title,
    required this.description,
    required this.color,
    required this.recommendations,
  });
}

// MAP YANG BERISI SEMUA TEKS DAN WARNA UNTUK SETIAP KATEGORI
final Map<int, ResultData> resultDataMap = {
  0: ResultData(
    title: 'Severely Stunted',
    description:
        'Tinggi badan sangat rendah untuk usia anak (indikasi stunting berat).',
    color: Colors.red.shade600,
    recommendations: [
      "Segera bawa anak ke fasilitas kesehatan untuk penanganan gizi lebih lanjut. 🏥❗",
      "Berikan makanan tinggi energi dan protein, bisa dibantu dengan Pemberian Makanan Tambahan (PMT). 🍗🍳",
      "Cegah infeksi dengan menjaga sanitasi dan imunisasi lengkap. 🛁💉",
      "Konsultasi dengan ahli gizi atau dokter anak untuk rencana pemulihan gizi. 🧑‍⚕️📋",
      "Libatkan keluarga dalam merawat dan menstimulasi anak setiap hari. Keterlibatan orang tua sangat penting. 👨‍👩‍👧",
    ],
  ),
  1: ResultData(
    title: 'Stunted',
    description:
        'Tinggi badan anak lebih rendah dari standar usianya (indikasi stunting ringan sampai sedang).',
    color: Colors.orange.shade600,
    recommendations: [
      "Ayo ke posyandu atau puskesmas untuk pemantauan tumbuh kembang si kecil! 🩺📊",
      "Perbaiki pola makan: tambahkan protein hewani, sayuran, dan buah setiap hari. 🐟🍌🥬",
      "Lakukan pemberian ASI dan MPASI dengan gizi lengkap sesuai umur. 🍲🍼",
      "Perhatikan kebersihan makanan dan air minum untuk mencegah infeksi. 🚰🍽️",
      "Dukung stimulasi anak secara emosional dan sosial. Peluk, ajak bicara, dan bermain. 🧸🧠",
    ],
  ),
  2: ResultData(
    title: 'Normal',
    description: 'Anak memiliki tinggi badan sesuai usianya.',
    color: Colors.green.shade600,
    recommendations: [
      "Pertahankan pola asuh dan gizi yang baik! 👶🍽️",
      "Ayo lanjutkan ASI eksklusif hingga usia 6 bulan, dan MPASI yang bergizi setelahnya! 🍼🥦",
      "Lakukan penimbangan rutin dan pantau tumbuh kembang si kecil ya! 📈",
      "Ciptakan lingkungan yang bersih dan bebas dari infeksi. 🧼🏡",
      "Berikan stimulasi aktif: ajak anak bermain dan berbicara setiap hari. 🎨🗣️",
    ],
  ),
  3: ResultData(
    title: 'Tinggi',
    description: 'Anak memiliki tinggi badan di atas rata-rata usianya.',
    color: Colors.blue.shade600,
    recommendations: [
      "Luar biasa! Si kecil tumbuh dengan optimal. 👏🌱",
      "Teruskan pola makan sehat dan seimbang, jangan lupa zat besi dan protein ya! 🥩🥚",
      "Jaga rutinitas tidur dan aktivitas fisik agar tumbuh kembang tetap ideal. 🛏️🏃",
      "Pastikan anak tetap mendapatkan imunisasi dan pemeriksaan kesehatan rutin. 💉👩‍⚕️",
      "Berikan kasih sayang dan perhatian penuh dalam setiap momen. ❤️",
    ],
  ),
};

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedGender;
  bool _isLoading = false;
  int? _predictedIndex;

  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_gizi.tflite');
      setState(() {});
      print('Model berhasil dimuat.');
    } catch (e) {
      print('Gagal memuat model: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat model: $e')));
    }
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
    if (_interpreter == null) return;

    setState(() => _isLoading = true);

    try {
      double genderValue = (_selectedGender == 'Laki-laki') ? 0.0 : 1.0;
      double ageValue = double.parse(_ageController.text);
      double heightValue = double.parse(_heightController.text);

      final scalerMean = [
        30.17380308928173,
        0.5041529268836933,
        88.6554341471572,
      ];
      final scalerScale = [
        17.575046595589747,
        0.49998275290083627,
        17.300925410791706,
      ];

      double scaledAge = (ageValue - scalerMean[0]) / scalerScale[0];
      double scaledGender = (genderValue - scalerMean[1]) / scalerScale[1];
      double scaledHeight = (heightValue - scalerMean[2]) / scalerScale[2];

      var input = Float32List.fromList([
        scaledAge,
        scaledGender,
        scaledHeight,
      ]).reshape([1, 3]);
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      _interpreter!.run(input, output);

      List<double> outputList = output[0].cast<double>();
      double maxProb = 0;
      int tempPredictedIndex = -1;
      for (int i = 0; i < outputList.length; i++) {
        if (outputList[i] > maxProb) {
          maxProb = outputList[i];
          tempPredictedIndex = i;
        }
      }

      setState(() => _predictedIndex = tempPredictedIndex);
    } catch (e) {
      print('Terjadi error saat prediksi: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediksi Status Gizi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Masukkan Data Balita',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        hint: const Text('Pilih Jenis Kelamin'),
                        items:
                            ['Laki-laki', 'Perempuan']
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (newValue) =>
                                setState(() => _selectedGender = newValue),
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wc),
                        ),
                        validator: (v) => v == null ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Umur (bulan)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tinggi Badan (cm)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.height),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      _isLoading || _interpreter == null ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text('Prediksi'),
                ),
                const SizedBox(height: 30),
                if (_predictedIndex != null)
                  PredictionResultCard(predictedIndex: _predictedIndex!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PredictionResultCard extends StatelessWidget {
  final int predictedIndex;
  const PredictionResultCard({super.key, required this.predictedIndex});

  @override
  Widget build(BuildContext context) {
    final data = resultDataMap[predictedIndex];
    if (data == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 16, indent: 16, endIndent: 16),
              for (int i = 0; i < data.recommendations.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    data.recommendations[i],
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
                if (i < data.recommendations.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
