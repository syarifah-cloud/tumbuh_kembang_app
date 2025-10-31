// lib/features/vaccine/vaccine_finder_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './location_picker_screen.dart';
import '../../models/place.dart'; // Kita akan buat model ini nanti

class VaccineFinderScreen extends StatefulWidget {
  const VaccineFinderScreen({super.key});

  @override
  State<VaccineFinderScreen> createState() => _VaccineFinderScreenState();
}

class _VaccineFinderScreenState extends State<VaccineFinderScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _currentAddress = "Memuat lokasi...";
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  List<Place> _placesList = [];

// GANTI BARIS YANG SALAH DENGAN INI:

  final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      _showErrorDialog("Layanan lokasi dinonaktifkan.", "Harap aktifkan GPS untuk melanjutkan.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
         _showErrorDialog("Izin Lokasi Ditolak", "Aplikasi ini membutuhkan izin lokasi untuk menemukan klinik terdekat.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      _showErrorDialog("Izin Lokasi Ditolak Permanen", "Kami tidak dapat meminta izin, harap aktifkan secara manual di pengaturan.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _updateLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Gagal Mendapatkan Lokasi", "Terjadi kesalahan saat mengambil lokasi Anda. Coba lagi.");
    }
  }
  
  void _updateLocation(LatLng newPosition) async {
    setState(() {
      _isLoading = true;
      _currentPosition = newPosition;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));
    }

    await _getAddressFromLatLng(newPosition);
    await _findNearbyVaccineLocations(newPosition);
    
    setState(() => _isLoading = false);
  }


  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
       // Menggunakan Plus Code jika tersedia untuk format yang mirip di screenshot
      List<String> plusCodeParts = (place.street ?? 'Unknown Location').split(' ');
      String displayCode = plusCodeParts.length > 2 ? "${plusCodeParts[0]} ${plusCodeParts[1]}" : place.street ?? 'Unknown Location';

      setState(() {
        _currentAddress = "$displayCode, ${place.subLocality}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Tidak dapat menemukan alamat";
      });
    }
  }

  Future<void> _findNearbyVaccineLocations(LatLng position) async {
    if (_apiKey == null) {
      _showErrorDialog("API Key Error", "Google Maps API Key tidak ditemukan.");
      return;
    }
    
    _markers.clear();
    _placesList.clear();

    const keywords = "vaksin OR klinik OR 'medical center' OR 'rumah sakit' OR puskesmas OR prodia";
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=5000&keyword=$keywords&key=$_apiKey';

    // di dalam fungsi _findNearbyVaccineLocations
   

    try {
      final response = await http.get(Uri.parse(url));
      print('Google Places Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        var newPlaces = results.map((p) => Place.fromJson(p)).toList();
        
        setState(() {
          _placesList = newPlaces;
          for (var place in _placesList) {
            _markers.add(
              Marker(
                markerId: MarkerId(place.placeId),
                position: place.location,
                infoWindow: InfoWindow(title: place.name, snippet: place.vicinity),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
          }
        });
      } else {
         _showErrorDialog("API Error", "Gagal memuat data dari Google Places. Status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Network Error", "Gagal terhubung ke server. Periksa koneksi internet Anda.");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () async {
            if (_currentPosition == null) return;
            final newLocation = await Navigator.push<LatLng>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPickerScreen(initialLocation: _currentPosition!),
              ),
            );
            if (newLocation != null) {
              _updateLocation(newLocation);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentAddress,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black54),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 0.8,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,-2)),
                        ]
                      ),
                      child: Column(
                        children: [
                          // Search and filter section
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const TextField(
                                    decoration: InputDecoration(
                                      icon: Icon(Icons.search),
                                      hintText: 'Cari klinik vaksin...',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildFilterChip('Filter'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Rating'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Terdekat', selected: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // List of places
                          Expanded(
                            child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : _placesList.isEmpty
                                ? const Center(child: Text("Tidak ada klinik ditemukan di sekitar sini."))
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: _placesList.length,
                                    itemBuilder: (context, index) {
                                      final place = _placesList[index];
                                      final distance = Geolocator.distanceBetween(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                        place.location.latitude,
                                        place.location.longitude,
                                      );
                                      return _buildPlaceItem(place, distance);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, {bool selected = false}) {
    return Chip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black)),
      backgroundColor: selected ? Colors.blue[700] : Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildPlaceItem(Place place, double distance) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withAlpha(25), // <-- Diperbaiki
        child: const Icon(Icons.local_hospital, color: Colors.blue),
      ),
      title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(place.vicinity),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${(distance / 1000).toStringAsFixed(2)} km'),
              const Text(' • '),
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text(place.rating.toString()),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}