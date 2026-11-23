import 'package:geolocator/geolocator.dart';
import 'package:streetbite/core/constants/app_constants.dart';

/// Result returned by [LocationService] including fallback metadata.
class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    required this.statusMessage,
  });

  final double latitude;
  final double longitude;
  final bool isFallback;
  final String statusMessage;
}

/// Resolves device GPS position with graceful permission & fallback handling.
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: AppGeoDefaults.defaultLatitude,
          longitude: AppGeoDefaults.defaultLongitude,
          isFallback: true,
          statusMessage:
              'Location services are disabled — showing ${AppGeoDefaults.defaultLocationLabel}',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          latitude: AppGeoDefaults.defaultLatitude,
          longitude: AppGeoDefaults.defaultLongitude,
          isFallback: true,
          statusMessage:
              'Location permission denied — showing ${AppGeoDefaults.defaultLocationLabel}',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isFallback: false,
        statusMessage: 'Using live GPS location',
      );
    } catch (_) {
      return const LocationResult(
        latitude: AppGeoDefaults.defaultLatitude,
        longitude: AppGeoDefaults.defaultLongitude,
        isFallback: true,
        statusMessage: 'Using ${AppGeoDefaults.defaultLocationLabel}',
      );
    }
  }
}
