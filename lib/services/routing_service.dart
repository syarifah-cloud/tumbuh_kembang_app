import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_final_project/models/route_info_model.dart'; // Ganti your_app_name

class RoutingService {
  Future<RouteInfo?> getRoute(LatLng start, LatLng end) async {
    // URL untuk OSRM public API
    // Formatnya: {lon},{lat};{lon},{lat}
    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final routeData = data['routes'][0];
          final geometry = routeData['geometry'];
          final distance = routeData['distance']; // dalam meter
          final duration = routeData['duration']; // dalam detik

          // Dekode polyline menjadi List<PointLatLng>
          final polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(geometry);

          // Konversi List<PointLatLng> menjadi List<LatLng>
          List<LatLng> routePoints = decodedPoints.map((point) => LatLng(point.latitude, point.longitude)).toList();

          return RouteInfo(
            points: routePoints,
            distanceInKm: distance / 1000, // Konversi meter ke km
            durationInMinutes: duration / 60, // Konversi detik ke menit
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching route: $e");
    }
    return null; // Kembalikan null jika gagal
  }
}