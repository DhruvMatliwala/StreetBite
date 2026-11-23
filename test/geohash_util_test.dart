import 'package:flutter_test/flutter_test.dart';
import 'package:streetbite/utils/geohash_util.dart';

void main() {
  group('GeohashUtil', () {
    test('encodes coordinates and decodes bounding box containing point', () {
      const lat = 21.1702;
      const lng = 72.8311;
      final hash = GeohashUtil.encode(lat, lng, precision: 7);

      expect(hash.length, 7);
      final bounds = GeohashUtil.decodeBounds(hash);
      expect(lat, greaterThanOrEqualTo(bounds.minLat));
      expect(lat, lessThanOrEqualTo(bounds.maxLat));
      expect(lng, greaterThanOrEqualTo(bounds.minLng));
      expect(lng, lessThanOrEqualTo(bounds.maxLng));
    });

    test('neighbors returns 9 unique cells of equal precision', () {
      final center = GeohashUtil.encode(21.1702, 72.8311, precision: 5);
      final cells = GeohashUtil.neighbors(center);

      expect(cells.length, 9);
      expect(cells, contains(center));
      expect(cells.every((c) => c.length == 5), isTrue);
    });

    test('precisionForRadiusKm maps radius thresholds accurately', () {
      expect(GeohashUtil.precisionForRadiusKm(0.5), 6);
      expect(GeohashUtil.precisionForRadiusKm(5.0), 5);
      expect(GeohashUtil.precisionForRadiusKm(25.0), 4);
    });

    test('queryBounds creates valid lexicographical ranges', () {
      final ranges = GeohashUtil.queryBounds(21.1702, 72.8311, 25.0);

      expect(ranges, isNotEmpty);
      for (final range in ranges) {
        expect(range.start.compareTo(range.end), lessThan(0));
      }
    });

    test('haversineDistanceKm calculates zero and realistic distance', () {
      expect(
        GeohashUtil.haversineDistanceKm(21.1702, 72.8311, 21.1702, 72.8311),
        closeTo(0.0, 0.0001),
      );

      final suratToAhmedabadKm = GeohashUtil.haversineDistanceKm(
        21.1702,
        72.8311,
        23.0225,
        72.5714,
      );
      expect(suratToAhmedabadKm, inInclusiveRange(200.0, 220.0));
    });

    test('formatDistance formats meters and kilometers clearly', () {
      expect(GeohashUtil.formatDistance(0.45), '450 m away');
      expect(GeohashUtil.formatDistance(2.36), '2.4 km away');
    });
  });
}
