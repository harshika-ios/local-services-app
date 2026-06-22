import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

// TODO: replace dummy markers with providers loaded from Supabase
// (`providers` table) once map filtering is wired up.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Default to New Delhi when the user's location isn't available.
  static const LatLng _fallbackCenter = LatLng(28.6139, 77.2090);

  static const List<({String id, String name, String service, LatLng pos})>
      _dummyProviders = [
    (
      id: 'mock-p1',
      name: 'Raj Electrician',
      service: 'Electrician',
      pos: LatLng(28.5708, 77.3260),
    ),
    (
      id: 'mock-p2',
      name: 'Amit Plumber',
      service: 'Plumber',
      pos: LatLng(28.5670, 77.2410),
    ),
    (
      id: 'mock-p3',
      name: 'Suresh Carpenter',
      service: 'Carpenter',
      pos: LatLng(28.6448, 77.2167),
    ),
  ];

  GoogleMapController? _controller;
  LatLng? _userLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = pos == null ? null : LatLng(pos.latitude, pos.longitude);
      _loading = false;
    });
  }

  Set<Marker> _buildMarkers() {
    return _dummyProviders
        .map(
          (p) => Marker(
            markerId: MarkerId(p.id),
            position: p.pos,
            infoWindow: InfoWindow(title: p.name, snippet: p.service),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final center = _userLocation ?? _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 12),
              myLocationEnabled: _userLocation != null,
              myLocationButtonEnabled: _userLocation != null,
              markers: _buildMarkers(),
              onMapCreated: (c) => _controller = c,
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
