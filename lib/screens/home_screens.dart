// lib/screens/home_screen.dart (Final dengan Horizontal Scroll Menu)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// Import model dan service
import '../models/child_profile.dart';
import '../models/article.dart';
import '../services/article_service.dart';

// Import screens
import './add_child_profile_screen.dart';
import './diary_screen.dart';
import './milestone_screen.dart';
import './prediction_screen.dart';
import './clinic_list_screen.dart';
import './jaundice_prediction_screen.dart'; // Pastikan Anda membuat file ini nanti

// Model kecil untuk item fitur agar lebih rapi
class FeatureItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  FeatureItem({required this.title, required this.icon, required this.onTap});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ArticleService _articleService = ArticleService();
  late Future<List<Article>> _articlesFuture;

  @override
  void initState() {
    super.initState();
    _articlesFuture = _articleService.fetchArticles();
  }

  String _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (months < 0 || (months == 0 && now.day < dob.day)) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years tahun ${months > 0 ? '$months bulan' : ''}'.trim();
    } else if (months > 0) {
      return '$months bulan';
    } else {
      return '${now.difference(dob).inDays} hari';
    }
  }

  void _navigateToProfileScreen({ChildProfile? profile}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChildProfileScreen(existingProfile: profile),
      ),
    );
  }

  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: ${url.toString()}')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _articlesFuture = _articleService.fetchArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildProfileStream();
  }

  Widget _buildProfileStream() {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Sesi Anda telah berakhir. Silakan login kembali.")),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('child_profiles').where('userId', isEqualTo: currentUser!.uid).limit(1).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error memuat data: ${snapshot.error}")));
        }

        ChildProfile? currentProfile = snapshot.hasData && snapshot.data!.docs.isNotEmpty
            ? ChildProfile.fromFirestore(snapshot.data!.docs.first)
            : null;

        return Scaffold(
          body: Container(
            color: Colors.grey[50],
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, profile: currentProfile),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 0, 16),
                      child: Text("Fitur Utama", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _buildFeaturesHorizontalList(context, profile: currentProfile),
                    const SizedBox(height: 20),
                    _buildArticleSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {ChildProfile? profile}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hai Parents!', style: TextStyle(color: Colors.white, fontSize: 24)),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          const Text('Profil Anak', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (profile == null) _buildEmptyProfileCard(context) else _buildFilledProfileCard(context, profile),
        ],
      ),
    );
  }

  Widget _buildEmptyProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE0F7FA), child: Icon(Icons.child_care, size: 30, color: Colors.blue)),
          const SizedBox(height: 8),
          const Text('Anda belum punya profil anak'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToProfileScreen(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Profil Anak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledProfileCard(BuildContext context, ChildProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: profile.photoPath != null && profile.photoPath!.isNotEmpty ? FileImage(File(profile.photoPath!)) : null,
            child: profile.photoPath == null || profile.photoPath!.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(_calculateAge(profile.dateOfBirth), style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateToProfileScreen(profile: profile), tooltip: 'Edit Profil'),
        ],
      ),
    );
  }

  Widget _buildFeaturesHorizontalList(BuildContext context, {ChildProfile? profile}) {
    void showProfileSnackbar() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi profil anak terlebih dahulu.')));

    final List<FeatureItem> features = [
      FeatureItem(
        title: 'Tumbuh Kembang', icon: Icons.show_chart,
        onTap: () {
          if (profile == null) { showProfileSnackbar(); } 
          else { Navigator.push(context, MaterialPageRoute(builder: (context) => MilestoneScreen(childProfile: profile))); }
        },
      ),
      FeatureItem(
        title: 'Vaksin', icon: Icons.shield_outlined,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ClinicListScreen()));
        },
      ),
      FeatureItem(
        title: 'Diary Anak', icon: Icons.book_outlined,
        onTap: () {
          if (profile == null) { showProfileSnackbar(); } 
          else { Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryScreen(childProfile: profile))); }
        },
      ),
      FeatureItem(
        title: 'Prediksi Gizi', icon: Icons.child_care,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictionPage()));
        },
      ),
      FeatureItem(
        title: 'Bayi Kuning', icon: Icons.flare,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Prediksi Bayi Kuning akan segera hadir!')));
          // Uncomment baris di bawah ini setelah Anda membuat JaundicePredictionScreen
          Navigator.push(context, MaterialPageRoute(builder: (context) => const JaundicePredictionScreen()));
        },
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 10),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _buildFeatureCard(
            context,
            icon: feature.icon,
            label: feature.title,
            onTap: feature.onTap,
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(50)),
              child: Icon(icon, size: 32, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Artikel Untuk Parents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FutureBuilder<List<Article>>(
            future: _articlesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Gagal memuat artikel: ${snapshot.error}"));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada artikel yang ditemukan."));
              
              final articles = snapshot.data!;
              return ListView.builder(
                itemCount: articles.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => _buildArticleCard(articles[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () { 
        // Tambahkan print ini untuk debugging
        print("KLIK TERDETEKSI! URL: ${article.url}");
        if (article.url.isNotEmpty) _launchURL(Uri.parse(article.url)); },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Row(
          children: [
            if (article.urlToImage != null)
              Image.network(
                article.urlToImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 100, height: 100, child: Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('${article.sourceName} • ${DateFormat('dd MMM yyyy').format(article.publishedAt)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}