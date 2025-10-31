// lib/models/place.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String placeId;
  final String name;
  final String vicinity;
  final double rating;
  final LatLng location;

  Place({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.rating,
    required this.location,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      placeId: json['place_id'],
      name: json['name'],
      vicinity: json['vicinity'] ?? 'Alamat tidak tersedia',
      rating: (json['rating'] ?? 0.0).toDouble(),
      location: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
    );
  }
}