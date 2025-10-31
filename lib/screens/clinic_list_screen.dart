// lib/screens/clinic_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_final_project/models/clinic_model.dart';
import 'package:flutter_final_project/providers/location_provider.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Clinic> _filteredClinics = [];

  void _filterClinics() {
    final locationProvider = context.read<LocationProvider>();
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClinics = locationProvider.nearbyClinics.where((clinic) {
        final clinicName = clinic.name.toLowerCase();
        return clinicName.contains(query);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterClinics);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clinics = context.read<LocationProvider>().nearbyClinics;
      setState(() {
        _filteredClinics = clinics;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (_searchController.text.isEmpty) {
          _filteredClinics = locationProvider.nearbyClinics;
        }

        return Scaffold(
          appBar: AppBar(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Vaksin'),
            actions: [_buildAppBarLocation(locationProvider)],
          ),
          body: _buildBody(locationProvider),
        );
      },
    );
  }

  Widget _buildAppBarLocation(LocationProvider provider) {
    if (provider.isLoadingLocation) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (provider.errorMessage != null) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.error_outline, color: Colors.red),
      );
    }
    return GestureDetector(
      onTap: () {
        if (provider.userLocation != null) Navigator.pushNamed(context, '/set-location');
      },
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 4),
          Text(
            '${provider.locationCode}, ...',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildBody(LocationProvider provider) {
    if (provider.isLoadingLocation) {
      return const Center(child: Text("Mencari lokasi Anda..."));
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => provider.determinePosition(),
                child: const Text("Coba Lagi"),
              )
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSearchBox(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildConsultationBanner(),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _buildClinicList(provider),
        ),
      ],
    );
  }

  Widget _buildClinicList(LocationProvider provider) {
    if (provider.isFetchingClinics) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.clinicFetchError != null) {
      return Center(child: Text("Gagal memuat klinik: ${provider.clinicFetchError}"));
    }
    if (provider.nearbyClinics.isEmpty) {
      return const Center(child: Text("Tidak ada klinik yang ditemukan di sekitar Anda."));
    }
    if (_filteredClinics.isEmpty) {
      return const Center(child: Text("Tidak ada klinik yang cocok dengan pencarian Anda."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredClinics.length,
      itemBuilder: (context, index) => _buildClinicListItem(_filteredClinics[index]),
      separatorBuilder: (context, index) => const Divider(height: 32),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama klinik atau rumah sakit...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildConsultationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.waving_hand, color: Colors.orange, size: 40),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('Konsultasikan vaksin anak Anda di Rumah Sakit/Klinik terbaik pilihan Anda', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Color(0xFFFBE9E7), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 12),
          ),
        ],
      ),
    );
  }

  // --- PERUBAHAN DI SINI ---
  Widget _buildClinicListItem(Clinic clinic) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/map-route', arguments: clinic);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget CircleAvatar dan SizedBox di bawah ini telah dihapus.
          /*
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.local_hospital, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          */
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Kita akan menggabungkan semua info dalam satu Text untuk mengatasi overflow
                Text(
                  // Menampilkan kota jika ada, jika tidak, langsung ke jarak.
                  '${clinic.city ?? ''}${clinic.city != null ? ' • ' : ''}${clinic.distanceInKm.toStringAsFixed(2)} km • ★ 5.0',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}