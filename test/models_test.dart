import 'package:flutter_test/flutter_test.dart';
import 'package:streetbite/models/menu_item.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';

void main() {
  group('Domain Models JSON Serialization', () {
    test('MenuItem serializes and deserializes cleanly', () {
      const item = MenuItem(
        id: 'm1',
        name: 'Paneer Kurkure Momos',
        price: 120.0,
        isVeg: true,
        category: 'Momos',
        description: 'Crispy momos with garlic dip',
      );

      final decoded = MenuItem.fromJson(item.toJson());
      expect(decoded, equals(item));
    });

    test('Review round-trip and averageRating', () {
      final now = DateTime.utc(2026, 1, 15, 18, 30);
      final review = Review(
        id: 'r1',
        stallId: 's1',
        authorUid: 'u1',
        authorName: 'Aarav',
        tasteRating: 5.0,
        hygieneRating: 4.0,
        comment: 'Delicious and clean!',
        createdAt: now,
      );

      final decoded = Review.fromJson(review.toJson());
      expect(decoded.id, 'r1');
      expect(decoded.averageRating, 4.5);
      expect(decoded.createdAt.toUtc(), now);
    });

    test('Stall round-trip, computed ratings, startingPrice, and tokens', () {
      final now = DateTime.utc(2026, 1, 15, 18, 30);
      const items = <MenuItem>[
        MenuItem(id: '1', name: 'Butter Locho', price: 70, category: 'Surti'),
        MenuItem(id: '2', name: 'Sev Khamani', price: 60, category: 'Surti'),
      ];
      final tokens = Stall.buildSearchableTokens(
        name: 'Gopi Surti Cart',
        menuItems: items,
        crowdTags: const <String>['Pure veg'],
      );

      final stall = Stall(
        id: 's1',
        vendorId: 'v1',
        name: 'Gopi Surti Cart',
        description: 'Authentic Surti snacks',
        address: 'Athwa Gate, Surat',
        latitude: 21.1815,
        longitude: 72.8150,
        geohash: 'te7pg',
        isOpen: true,
        operatingHours: '7 AM - 9 PM',
        menuItems: items,
        searchableItems: tokens,
        crowdTags: const <String>['Pure veg'],
        tasteRating: 4.8,
        hygieneRating: 4.6,
        reviewCount: 12,
        createdAt: now,
        updatedAt: now,
      );

      final decoded = Stall.fromJson(stall.toJson());
      expect(decoded.name, 'Gopi Surti Cart');
      expect(decoded.menuItems.length, 2);
      expect(decoded.overallRating, closeTo(4.7, 0.001));
      expect(decoded.startingPrice, 60.0);
      expect(decoded.searchableItems, contains('locho'));
      expect(decoded.searchableItems, contains('khamani'));
    });
  });
}
