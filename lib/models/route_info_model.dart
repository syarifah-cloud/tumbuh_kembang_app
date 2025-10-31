import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> points; // Daftar koordinat untuk polyline
  final double distanceInKm;   // Jarak dalam kilometer
  final double durationInMinutes; // Durasi dalam menit

  RouteInfo({
    required this.points,
    required this.distanceInKm,
    required this.durationInMinutes,
  });
}