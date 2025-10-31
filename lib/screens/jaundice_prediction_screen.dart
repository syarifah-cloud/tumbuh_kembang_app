import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class JaundicePredictionScreen extends StatefulWidget {
  const JaundicePredictionScreen({super.key});

  @override
  State<JaundicePredictionScreen> createState() => _JaundicePredictionScreenState();
}

class _JaundicePredictionScreenState extends State<JaundicePredictionScreen> {
  Interpreter? _interpreter;
  File? _imageFile;
  String? _predictionResult;
  bool _isLoading = false;

  final int _inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model (1).tflite');
      setState(() {});
      print('Model berhasil dimuat.');
    } catch (e) {
      print('Gagal memuat model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _predictionResult = null;
      });
    }
  }

  Future<void> _predict() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih gambar terlebih dahulu!')));
      return;
    }
    if (_interpreter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model belum siap, coba lagi.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Float32List imageAsList = _preprocessImage(_imageFile!);
      var inputTensor = imageAsList.reshape([1, _inputSize, _inputSize, 3]);

      var output = List.filled(2, 0.0).reshape([1, 2]);
      _interpreter!.run(inputTensor, output);

      int predictedIndex = output[0][0] > output[0][1] ? 0 : 1;
      double confidence = output[0][predictedIndex];
      String resultText = predictedIndex == 0 ? 'Jaundice' : 'Normal';

      setState(() {
        _predictionResult = '$resultText (Confidence: ${(confidence * 100).toStringAsFixed(2)}%)';
      });
    } catch (e) {
      setState(() {
        _predictionResult = 'Error saat prediksi: $e';
      });
      print('Error saat prediksi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Float32List _preprocessImage(File imageFile) {
    img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());
    if (originalImage == null) throw Exception("Gagal membaca file gambar.");

    img.Image resizedImage = img.copyResize(originalImage, width: _inputSize, height: _inputSize);

    var inputBuffer = Float32List(1 * _inputSize * _inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        var pixel = resizedImage.getPixel(x, y);
        inputBuffer[bufferIndex++] = pixel.r / 255.0;
        inputBuffer[bufferIndex++] = pixel.g / 255.0;
        inputBuffer[bufferIndex++] = pixel.b / 255.0;
      }
    }
    return inputBuffer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Jaundice Bayi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 80, color: Colors.grey.shade500),
                              const SizedBox(height: 10),
                              const Text('Pilih Gambar', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: 300),
                          ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text('Kamera'), onPressed: () => _pickImage(ImageSource.camera)),
                    OutlinedButton.icon(icon: const Icon(Icons.photo_library), label: const Text('Galeri'), onPressed: () => _pickImage(ImageSource.gallery)),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: (_isLoading || _imageFile == null || _interpreter == null) ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Lakukan Prediksi'),
                ),
                const SizedBox(height: 30),
                if (_predictionResult != null && !_isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _predictionResult!.toLowerCase().contains('jaundice') ? Colors.orange.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _predictionResult!.toLowerCase().contains('jaundice') ? Colors.orange.shade400 : Colors.green.shade400,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _predictionResult!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _predictionResult!.toLowerCase().contains('jaundice') ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _predictionResult!.toLowerCase().contains('jaundice')
                              ? 'Segera periksakan bayi Anda ke dokter untuk evaluasi lebih lanjut.'
                              : 'Hasil menunjukkan kondisi normal. Tetap pantau kondisi bayi secara berkala.',
                          style: TextStyle(
                            fontSize: 16,
                            color: _predictionResult!.toLowerCase().contains('jaundice') ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
                                                                                                                                                 