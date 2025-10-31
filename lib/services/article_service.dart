// lib/services/article_service.dart (dengan filter di sisi klien)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import '../models/article.dart'; // Sesuaikan path jika perlu

class ArticleService {
  final String _rssUrl = 'https://mommiesdaily.com/feed/';
  final Xml2Json _transformer = Xml2Json();

  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'
  };

  Future<List<Article>> fetchArticles() async {
    // --- TAMBAHAN BARU: Definisikan kata kunci yang Anda inginkan di sini ---
    final List<String> keywords = [
      'bayi',
      'mpasi',
      'menyusui',
      'parenting',
      'anak',
      'balita',
      'kehamilan',
      'gizi',
      'kesehatan',
      'stimulasi',
      'perkembangan',
      'tumbuh kembang',
      'hamil',
      'ibu',
    ];
    // -----------------------------------------------------------------------

    try {
      final response = await http.get(Uri.parse(_rssUrl), headers: _headers);
      
      if (response.statusCode == 200) {
        _transformer.parse(response.body);
        final String jsonString = _transformer.toGData();
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        final List<dynamic> items = jsonData['rss']['channel']['item'];

        final List<Article> allArticles = items.map((item) {
          String? imageUrl;
          if (item['media\$content'] != null) {
            imageUrl = item['media\$content']['url'];
          } else if (item['enclosure'] != null) {
            imageUrl = item['enclosure']['url'];
          }

          return Article(
            title: item['title']?['\$t'] ?? 'Tanpa Judul',
            url: item['link']?['\$t'] ?? '', 
            description: item['description']?['\$t']?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '...',
            publishedAt: DateTime.tryParse(item['pubDate']?['\$t'] ?? '') ?? DateTime.now(),
            urlToImage: imageUrl,
            sourceName: 'Mommies Daily',
          );
        }).toList();

        // --- FILTER DI SINI ---
        final List<Article> filteredArticles = allArticles.where((article) {
          final String titleLower = article.title.toLowerCase();
          final String descLower = article.description?.toLowerCase() ?? '';

          // Kembalikan true jika salah satu kata kunci ditemukan di judul atau deskripsi
          return keywords.any((keyword) => 
            titleLower.contains(keyword) || descLower.contains(keyword)
          );
        }).toList();

        return filteredArticles;
        // -----------------------

      } else {
        throw Exception('Gagal memuat feed: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error memuat artikel dari RSS: $e');
    }
  }
}