import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Clinic {
  final String name;
  final String? city;
  final double distanceInKm;
  final LatLng location;
  final double rating;
  final bool isPartner;
  final bool hasHomecare;
  final String logoAsset;

  Clinic({
    required this.name,
    this.city,
    required this.distanceInKm,
    required this.location,
    this.rating = 0.0,
    this.isPartner = false,
    this.hasHomecare = false,
    this.logoAsset = '',
  });

  // Factory constructor yang lebih aman
  factory Clinic.fromOverpassJson(Map<String, dynamic> json, LatLng userLocation) {
    final tags = json['tags'] as Map<String, dynamic>;
    
    // --- PERBAIKAN KRITIS DI SINI ---
    // Pastikan lat dan lon ada, jika tidak, gunakan nilai default yang tidak valid
    // yang akan kita filter nanti.
    final lat = json['lat'] as double? ?? 999.0;
    final lon = json['lon'] as double? ?? 999.0;

    // Jika lat atau lon tidak valid, kita akan mengabaikan data ini.
    if (lat == 999.0 || lon == 999.0) {
      // Mengembalikan objek 'dummy' yang bisa kita filter
      return Clinic(name: 'Invalid Data', distanceInKm: 9999, location: const LatLng(0,0));
    }
    // ---------------------------------

    final clinicLocation = LatLng(lat, lon);

    final distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      clinicLocation.latitude,
      clinicLocation.longitude,
    );
    
    return Clinic(
      name: tags['name'] ?? 'Fasilitas Kesehatan',
      city: tags['addr:city'],
      location: clinicLocation,
      distanceInKm: distanceInMeters / 1000,
      // Beri nilai default untuk rating dan lainnya dari data dummy yang kita punya
      rating: 5.0, // Default rating
      isPartner: (tags['name']?.toString().toLowerCase().contains('prodia') ?? false) ||
                 (tags['name']?.toString().toLowerCase().contains('agian') ?? false),
      hasHomecare: (tags['name']?.toString().toLowerCase().contains('senior') ?? false) ||
                   (tags['name']?.toString().toLowerCase().contains('agian') ?? false),
    );
  }
}