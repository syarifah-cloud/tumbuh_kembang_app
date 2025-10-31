// lib/features/vaccine/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerScreen({super.key, required this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _pickedLocation;
  String _address = "Memuat alamat...";
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _getAddressFromLatLng(_pickedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (_isGeocoding) return; // Prevent multiple requests
    setState(() {
      _isGeocoding = true;
      _address = "Mencari alamat...";
    });
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      
      setState(() {
        // Mirip dengan screenshot: PQ9W+Q52, Keputih, Sukolilo...
        final street = place.street ?? 'Lokasi tidak diketahui';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final country = place.country ?? '';
        _address = '$street, $subLocality, $locality, $country';
      });
    } catch (e) {
      setState(() => _address = "Gagal mendapatkan alamat");
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Lokasi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 16,
            ),
            onCameraMove: (CameraPosition position) {
              setState(() {
                _pickedLocation = position.target;
              });
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_pickedLocation);
            },
          ),
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8.0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pilih Lokasi', 
                      style: Theme.of(context).textTheme.titleLarge
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isGeocoding ? null : () {
                        Navigator.of(context).pop(_pickedLocation);
                      },
                      child: _isGeocoding 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Set Lokasi'),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}