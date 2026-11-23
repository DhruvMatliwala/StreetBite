import 'package:url_launcher/url_launcher.dart';

/// Deep-links directly into Google Maps for turn-by-turn stall navigation.
class NavigationService {
  Future<bool> openTurnByTurnDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      final launched = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    }

    final encodedLabel = Uri.encodeComponent(label ?? 'StreetBite Stall');
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)',
    );
    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
