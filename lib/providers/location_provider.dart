// lib/providers/location_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_final_project/models/clinic_model.dart'; // Ganti your_app_name
import 'package:flutter_final_project/models/place_suggestion.dart';

class LocationProvider with ChangeNotifier {
  //------------------------------------------------------------------
  //  STATE VARIABLES
  //------------------------------------------------------------------

  // State untuk Lokasi Pengguna
  LatLng? _userLocation;
  String _locationCode = "Mencari...";
  String _fullAddress = "Harap tunggu...";
  bool _isLoadingLocation = true;
  String? _errorMessage;
  
  // State untuk Rekomendasi Klinik Terdekat (otomatis)
  List<Clinic> _nearbyClinics = [];
  bool _isFetchingClinics = false;
  String? _clinicFetchError;

  // State untuk Hasil Pencarian Klinik Online (dipicu pengguna)
  List<Clinic> _clinicSearchResults = [];
  bool _isSearchingClinicsOnline = false;

  // State untuk Pencarian Alamat di Halaman Peta
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;

  //------------------------------------------------------------------
  //  GETTERS
  //------------------------------------------------------------------

  LatLng? get userLocation => _userLocation;
  String get locationCode => _locationCode;
  String get fullAddress => _fullAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;

  List<Clinic> get nearbyClinics => _nearbyClinics;
  bool get isFetchingClinics => _isFetchingClinics;
  String? get clinicFetchError => _clinicFetchError;

  List<Clinic> get clinicSearchResults => _clinicSearchResults;
  bool get isSearchingClinicsOnline => _isSearchingClinicsOnline;

  List<PlaceSuggestion> get suggestions => _suggestions;
  bool get isSearching => _isSearching;

  //------------------------------------------------------------------
  //  CONSTRUCTOR
  //------------------------------------------------------------------

  LocationProvider() {
    determinePosition();
  }
  
  //------------------------------------------------------------------
  //  LOGIKA UTAMA: LOKASI PENGGUNA & REKOMENDASI TERDEKAT
  //------------------------------------------------------------------
  
  Future<void> determinePosition() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi tidak aktif.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Izin lokasi ditolak permanen.');

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _userLocation = LatLng(position.latitude, position.longitude);
      await _getAddressFromLatLng(_userLocation!);
      await _fetchNearbyClinics(_userLocation!);
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNearbyClinics(LatLng location) async {
    _isFetchingClinics = true;
    _clinicFetchError = null;
    notifyListeners();
    const radiusInMeters = 5000; // Radius 5km untuk rekomendasi otomatis
    final query = "[out:json];(node[amenity~\"hospital|clinic|doctors\"](around:$radiusInMeters,${location.latitude},${location.longitude});way[amenity~\"hospital|clinic|doctors\"](around:$radiusInMeters,${location.latitude},${location.longitude});relation[amenity~\"hospital|clinic|doctors\"](around:$radiusInMeters,${location.latitude},${location.longitude}););out center;";
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    try {
      final response = await http.post(url, body: {'data': query});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        _nearbyClinics = elements
            .where((e) => e['tags']?['name'] != null)
            .map((e) => Clinic.fromOverpassJson(e, location))
            .where((clinic) => clinic.name != 'Invalid Data') // PERBAIKAN: Filter data tidak valid
            .toList();
        _nearbyClinics.sort((a, b) => a.distanceInKm.compareTo(b.distanceInKm));
      } else {
        throw Exception('Gagal memuat data klinik: ${response.statusCode}');
      }
    } catch (e) {
      _clinicFetchError = e.toString();
    } finally {
      _isFetchingClinics = false;
      notifyListeners();
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _fullAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
        _locationCode = place.locality ?? "Lokasi Ditemukan";
      }
    } catch (e) {
      _fullAddress = "Gagal mendapatkan alamat dari koordinat.";
    }
  }
  
  //------------------------------------------------------------------
  //  LOGIKA UNTUK PENCARIAN KLINIK ONLINE
  //------------------------------------------------------------------
  
  Future<void> searchClinicsOnline(String query) async {
    if (query.length < 3 || _userLocation == null) {
      _clinicSearchResults = [];
      notifyListeners();
      return;
    }

    _isSearchingClinicsOnline = true;
    notifyListeners();

    // Mencari dengan radius lebih besar (25km) dan query nama
    const radiusInMeters = 25000;
    final queryData = "[out:json];(node[amenity~\"hospital|clinic|doctors\"][\"name\"~\"$query\",i](around:$radiusInMeters,${_userLocation!.latitude},${_userLocation!.longitude}););out center;";
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    try {
      final response = await http.post(url, body: {'data': queryData});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        _clinicSearchResults = elements
            .where((e) => e['tags']?['name'] != null)
            .map((e) => Clinic.fromOverpassJson(e, _userLocation!))
            .where((clinic) => clinic.name != 'Invalid Data')
            .toList();
      } else {
        _clinicSearchResults = [];
      }
    } catch (e) {
      _clinicSearchResults = [];
    } finally {
      _isSearchingClinicsOnline = false;
      notifyListeners();
    }
  }

  void addSearchedClinicToTop(Clinic clinic) {
    // Cek jika klinik sudah ada di daftar rekomendasi untuk menghindari duplikat
    final isAlreadyInList = _nearbyClinics.any((c) => c.name == clinic.name && c.location == clinic.location);
    if (!isAlreadyInList) {
      _nearbyClinics.insert(0, clinic);
    }
    clearClinicSearchResults();
  }
  
  void clearClinicSearchResults() {
    _clinicSearchResults = [];
    notifyListeners();
  }
  
  //------------------------------------------------------------------
  //  LOGIKA UNTUK PENCARIAN ALAMAT DI HALAMAN PETA
  //------------------------------------------------------------------
  
  Future<void> searchLocation(String query) async {
    if (query.length < 3) {
      _suggestions = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _suggestions = data.map((json) => PlaceSuggestion.fromJson(json)).toList();
      } else {
        _suggestions = [];
      }
    } catch (e) {
      _suggestions = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectSearchedLocation(PlaceSuggestion suggestion) {
    final newLocation = LatLng(suggestion.lat, suggestion.lon);
    _userLocation = newLocation;
    _getAddressFromLatLng(newLocation);
    _suggestions = [];
    // Setelah lokasi baru dipilih, ambil ulang rekomendasi klinik terdekat
    _fetchNearbyClinics(newLocation);
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }
}