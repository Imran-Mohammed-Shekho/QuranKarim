import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_time_model.dart';

class LocationService {
  Future<LocationFetchResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationFetchResult.failure(
        failureType: LocationFailureType.servicesDisabled,
        message:
            'Location services are disabled. Enable GPS to calculate prayer times.',
      );
    }

    final permissionFailure = await _ensurePermission();
    if (permissionFailure != null) {
      return permissionFailure;
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return const LocationFetchResult.failure(
          failureType: LocationFailureType.unavailable,
          message:
              'Current location could not be determined right now. Try again in a moment.',
        );
      }

      final city = await _resolveCity(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return LocationFetchResult.success(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          city: city,
        ),
      );
    } catch (_) {
      return const LocationFetchResult.failure(
        failureType: LocationFailureType.unavailable,
        message:
            'Current location could not be determined right now. Try again in a moment.',
      );
    }
  }

  Future<LocationFetchResult?> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return const LocationFetchResult.failure(
        failureType: LocationFailureType.permissionDenied,
        message:
            'Location permission was denied. Allow location access to load prayer times.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationFetchResult.failure(
        failureType: LocationFailureType.permissionDeniedForever,
        message:
            'Location permission is permanently denied. Open app settings to enable it.',
      );
    }

    return null;
  }

  Future<String> _resolveCity({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return 'Current location';
      }

      final place = placemarks.first;
      final locality = place.locality?.trim();
      final adminArea = place.administrativeArea?.trim();
      if (locality != null && locality.isNotEmpty) {
        return locality;
      }
      if (adminArea != null && adminArea.isNotEmpty) {
        return adminArea;
      }
    } catch (_) {
      // Reverse geocoding is optional; fall back to generic copy.
    }
    return 'Current location';
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
