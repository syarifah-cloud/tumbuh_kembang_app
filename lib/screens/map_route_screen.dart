// lib/screens/map_route_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_final_project/models/clinic_model.dart'; // Ganti your_app_name
import 'package:flutter_final_project/models/route_info_model.dart';
import 'package:flutter_final_project/providers/location_provider.dart';
import 'package:flutter_final_project/services/routing_service.dart';

class MapRouteScreen extends StatefulWidget {
  final Clinic clinic;

  const MapRouteScreen({super.key, required this.clinic});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  final RoutingService _routingService = RoutingService();
  RouteInfo? _routeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final userLocation = context.read<LocationProvider>().userLocation;
    if (userLocation != null) {
      _fetchRoute(userLocation, widget.clinic.location);
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final route = await _routingService.getRoute(start, end);
    if (mounted) {
      setState(() {
        _routeInfo = route;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = context.read<LocationProvider>().userLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_routeInfo == null || userLocation == null)
            const Center(child: Text("Gagal memuat rute. Silakan coba lagi."))
          else
            _buildMap(userLocation, widget.clinic.location),
          
          if (_routeInfo != null) _buildRouteInfoCard(),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng userLocation, LatLng clinicLocation) {
    final LatLngBounds bounds = LatLngBounds.fromPoints([userLocation, clinicLocation]);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80.0),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routeInfo!.points,
              strokeWidth: 5.0,
              color: Colors.blue,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            _buildMarker(userLocation, Icons.person_pin, Colors.blue, "Anda"),
            _buildMarker(clinicLocation, Icons.local_hospital, Colors.red, "Klinik"),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker(LatLng point, IconData icon, Color color, String label) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: point,
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          Text(
            label, 
            style: TextStyle(
              color: color, 
              fontWeight: FontWeight.bold, 
              backgroundColor: Colors.white.withAlpha(128)
            )
          )
        ],
      ),
    );
  }

  // --- PERUBAHAN DI SINI ---
  Widget _buildRouteInfoCard() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding vertikal saja
          child: Row(
            // Mengubah alignment agar 2 item terlihat seimbang
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoItem(
                Icons.timer, 
                "${_routeInfo!.durationInMinutes.toStringAsFixed(0)} mnt"
              ),
              _infoItem(
                Icons.directions_car, 
                "${_routeInfo!.distanceInKm.toStringAsFixed(1)} km"
              ),
              // Tombol ElevatedButton sudah dihapus dari sini
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _infoItem(IconData icon, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}