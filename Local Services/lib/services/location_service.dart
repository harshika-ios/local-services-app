import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<Position?> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Fall back to lastKnownPosition if a fresh fix takes too long
    // (common on iOS simulators with no location set).
    try {
      return await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  // Returns a friendly place name like "Sector 18, Noida, Uttar Pradesh"
  // or null if the platform geocoder fails / returns no result.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((s) => s != null && s.isNotEmpty).cast<String>().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
