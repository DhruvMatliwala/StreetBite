import 'dart:math' as math;

/// Bounding box decoded from a Base32 geohash string.
class GeoBounds {
  const GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get centerLat => (minLat + maxLat) / 2.0;
  double get centerLng => (minLng + maxLng) / 2.0;
}

/// Inclusive lexicographical geohash prefix range for Firestore range queries.
class GeohashRange {
  const GeohashRange({required this.start, required this.end});

  final String start;
  final String end;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GeohashRange && other.start == start && other.end == end);
  }

  @override
  int get hashCode => Object.hash(start, end);
}

/// Pure-Dart Base32 geohash encoder, neighbor finder, and Haversine utility.
abstract final class GeohashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const double _earthRadiusKm = 6371.0;

  /// Encodes [latitude] and [longitude] into a Base32 geohash of [precision].
  static String encode(
    double latitude,
    double longitude, {
    int precision = 9,
  }) {
    assert(precision >= 1 && precision <= 12);
    final clampedLat = latitude.clamp(-90.0, 90.0);
    final clampedLng = longitude.clamp(-180.0, 180.0);

    var latMin = -90.0;
    var latMax = 90.0;
    var lngMin = -180.0;
    var lngMax = 180.0;

    var isEvenBit = true;
    var bit = 0;
    var charIndex = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isEvenBit) {
        final mid = (lngMin + lngMax) / 2.0;
        if (clampedLng >= mid) {
          charIndex = (charIndex << 1) | 1;
          lngMin = mid;
        } else {
          charIndex = charIndex << 1;
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2.0;
        if (clampedLat >= mid) {
          charIndex = (charIndex << 1) | 1;
          latMin = mid;
        } else {
          charIndex = charIndex << 1;
          latMax = mid;
        }
      }

      isEvenBit = !isEvenBit;
      bit++;

      if (bit == 5) {
        buffer.write(_base32[charIndex]);
        bit = 0;
        charIndex = 0;
      }
    }

    return buffer.toString();
  }

  /// Decodes a Base32 [geohash] into its latitude/longitude [GeoBounds].
  static GeoBounds decodeBounds(String geohash) {
    var latMin = -90.0;
    var latMax = 90.0;
    var lngMin = -180.0;
    var lngMax = 180.0;
    var isEvenBit = true;

    for (var i = 0; i < geohash.length; i++) {
      final charIdx = _base32.indexOf(geohash[i]);
      if (charIdx == -1) {
        throw ArgumentError.value(geohash, 'geohash', 'Invalid Base32 char');
      }
      for (var mask = 16; mask >= 1; mask >>= 1) {
        if (isEvenBit) {
          final mid = (lngMin + lngMax) / 2.0;
          if ((charIdx & mask) != 0) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2.0;
          if ((charIdx & mask) != 0) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isEvenBit = !isEvenBit;
      }
    }

    return GeoBounds(
      minLat: latMin,
      maxLat: latMax,
      minLng: lngMin,
      maxLng: lngMax,
    );
  }

  /// Returns the center cell plus up to 8 surrounding neighbor geohashes.
  static List<String> neighbors(String geohash) {
    if (geohash.isEmpty) return const <String>[];
    final bounds = decodeBounds(geohash);
    final latStep = bounds.maxLat - bounds.minLat;
    final lngStep = bounds.maxLng - bounds.minLng;
    final precision = geohash.length;

    final cells = <String>{geohash};
    for (var dLat = -1; dLat <= 1; dLat++) {
      for (var dLng = -1; dLng <= 1; dLng++) {
        if (dLat == 0 && dLng == 0) continue;
        final targetLat = (bounds.centerLat + dLat * latStep).clamp(-89.9999, 89.9999);
        var targetLng = bounds.centerLng + dLng * lngStep;
        if (targetLng > 180.0) targetLng -= 360.0;
        if (targetLng < -180.0) targetLng += 360.0;
        cells.add(encode(targetLat, targetLng, precision: precision));
      }
    }
    return cells.toList()..sort();
  }

  /// Selects an optimal geohash prefix precision for a 3x3 grid covering [radiusKm].
  static int precisionForRadiusKm(double radiusKm) {
    if (radiusKm <= 0.8) return 6;
    if (radiusKm <= 6.5) return 5;
    return 4;
  }

  /// Builds lexicographical Firestore prefix ranges for [radiusKm] around ([lat], [lng]).
  static List<GeohashRange> queryBounds(
    double lat,
    double lng,
    double radiusKm,
  ) {
    final precision = precisionForRadiusKm(radiusKm);
    final centerHash = encode(lat, lng, precision: precision);
    final allCells = neighbors(centerHash);

    return allCells
        .map((cell) => GeohashRange(start: cell, end: '$cell~'))
        .toList();
  }

  /// Computes great-circle distance in kilometers using the Haversine formula.
  static double haversineDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return _earthRadiusKm * c;
  }

  /// Formats a kilometer distance for concise UI display.
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180.0);
}
