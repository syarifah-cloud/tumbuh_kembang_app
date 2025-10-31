// lib/screens/set_location_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_final_project/models/place_suggestion.dart'; // Ganti your_app_name
import 'package:flutter_final_project/providers/location_provider.dart';
import 'package:flutter_final_project/utils/debouncer.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _debouncer.run(() {
          context.read<LocationProvider>().searchLocation(_searchController.text);
        });
      } else {
        context.read<LocationProvider>().clearSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final userLocation = locationProvider.userLocation;

        if (userLocation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Set Lokasi")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: userLocation,
                        child: const Icon(Icons.location_pin, color: Colors.blue, size: 50.0),
                      ),
                    ],
                  ),
                ],
              ),
              // UI Bagian Atas & Bawah
              _buildTopUI(),
              _buildBottomUI(locationProvider),
              // Tampilkan Hasil Pencarian
              if (locationProvider.suggestions.isNotEmpty || locationProvider.isSearching)
                _buildSearchResults(locationProvider),
            ],
          ),
        );
      },
    );
  }

  // PERUBAHAN: Widget ini sekarang berisi AppBar dan Search bar
  Widget _buildTopUI() {
    return Positioned(
      top: 40.0,
      left: 16.0,
      right: 16.0,
      child: Column(
        children: [
          // 1. Custom App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Set Lokasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 2. Search Bar
          Material(
            borderRadius: BorderRadius.circular(12),
            elevation: 4.0,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ketik nama jalan/rumah sakit/klinik',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PERUBAHAN: Widget ini sekarang hanya berisi detail alamat dan tombol
  Widget _buildBottomUI(LocationProvider locationProvider) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20.0, spreadRadius: 5.0)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // TextField sudah dipindahkan
            const SizedBox(height: 12), // Sedikit padding tambahan
            Text(locationProvider.locationCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(locationProvider.fullAddress, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Set Lokasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(LocationProvider locationProvider) {
    // PERUBAHAN: Menyesuaikan posisi daftar hasil agar muncul di bawah search bar baru
    return Positioned(
      top: 180.0, // Dulu 100, sekarang lebih rendah
      left: 16,
      right: 16,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: locationProvider.isSearching
              ? const Center(heightFactor: 3, child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: locationProvider.suggestions.length,
                  itemBuilder: (context, index) {
                    final PlaceSuggestion suggestion = locationProvider.suggestions[index];
                    return ListTile(
                      title: Text(suggestion.displayName),
                      onTap: () {
                        locationProvider.selectSearchedLocation(suggestion);
                        _mapController.move(
                          LatLng(suggestion.lat, suggestion.lon),
                          15.0,
                        );
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}