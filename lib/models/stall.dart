import 'package:streetbite/models/menu_item.dart';
import 'package:streetbite/models/review.dart';

/// Represents a hyper-local street food stall or mobile cart.
class Stall {
  const Stall({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.isOpen,
    required this.operatingHours,
    this.bannerImageUrl = '',
    this.galleryUrls = const <String>[],
    this.menuItems = const <MenuItem>[],
    this.searchableItems = const <String>[],
    this.crowdTags = const <String>[],
    this.tasteRating = 4.5,
    this.hygieneRating = 4.3,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String geohash;
  final bool isOpen;
  final String operatingHours;
  final String bannerImageUrl;
  final List<String> galleryUrls;
  final List<MenuItem> menuItems;
  final List<String> searchableItems;
  final List<String> crowdTags;
  final double tasteRating;
  final double hygieneRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get overallRating => (tasteRating + hygieneRating) / 2.0;

  double? get startingPrice {
    final available = menuItems.where((item) => item.isAvailable).toList();
    if (available.isEmpty) return null;
    available.sort((a, b) => a.price.compareTo(b.price));
    return available.first.price;
  }

  /// Generates normalized lowercase craving tokens for Firestore & local search.
  static List<String> buildSearchableTokens({
    required String name,
    required List<MenuItem> menuItems,
    required List<String> crowdTags,
  }) {
    final tokens = <String>{};

    void addTokens(String text) {
      final cleaned = text.trim().toLowerCase();
      if (cleaned.isEmpty) return;
      tokens.add(cleaned);
      for (final word in cleaned.split(RegExp(r'[\s,/&-]+'))) {
        if (word.length >= 2) {
          tokens.add(word);
        }
      }
    }

    addTokens(name);
    for (final item in menuItems) {
      addTokens(item.name);
      addTokens(item.category);
    }
    for (final tag in crowdTags) {
      addTokens(tag);
    }
    return tokens.take(150).toList();
  }

  factory Stall.fromJson(Map<String, dynamic> json) {
    final rawMenu = (json['menuItems'] as List<dynamic>?) ?? const <dynamic>[];
    final menuItems = rawMenu
        .whereType<Map<String, dynamic>>()
        .map(MenuItem.fromJson)
        .toList();

    final rawGallery =
        (json['galleryUrls'] as List<dynamic>?) ?? const <dynamic>[];
    final rawSearchable =
        (json['searchableItems'] as List<dynamic>?) ?? const <dynamic>[];
    final rawTags = (json['crowdTags'] as List<dynamic>?) ?? const <dynamic>[];

    return Stall(
      id: (json['id'] as String?) ?? '',
      vendorId: (json['vendorId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: (json['geohash'] as String?) ?? '',
      isOpen: (json['isOpen'] as bool?) ?? false,
      operatingHours: (json['operatingHours'] as String?) ?? '5:00 PM - 11:00 PM',
      bannerImageUrl: (json['bannerImageUrl'] as String?) ?? '',
      galleryUrls: rawGallery.map((e) => e.toString()).toList(),
      menuItems: menuItems,
      searchableItems: rawSearchable.map((e) => e.toString()).toList(),
      crowdTags: rawTags.map((e) => e.toString()).toList(),
      tasteRating: (json['tasteRating'] as num?)?.toDouble() ?? 4.5,
      hygieneRating: (json['hygieneRating'] as num?)?.toDouble() ?? 4.3,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: Review.parseFlexibleDateTime(json['createdAt']),
      updatedAt: Review.parseFlexibleDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'isOpen': isOpen,
      'operatingHours': operatingHours,
      'bannerImageUrl': bannerImageUrl,
      'galleryUrls': galleryUrls,
      'menuItems': menuItems.map((item) => item.toJson()).toList(),
      'searchableItems': searchableItems,
      'crowdTags': crowdTags,
      'tasteRating': tasteRating,
      'hygieneRating': hygieneRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Stall copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? geohash,
    bool? isOpen,
    String? operatingHours,
    String? bannerImageUrl,
    List<String>? galleryUrls,
    List<MenuItem>? menuItems,
    List<String>? searchableItems,
    List<String>? crowdTags,
    double? tasteRating,
    double? hygieneRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stall(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      menuItems: menuItems ?? this.menuItems,
      searchableItems: searchableItems ?? this.searchableItems,
      crowdTags: crowdTags ?? this.crowdTags,
      tasteRating: tasteRating ?? this.tasteRating,
      hygieneRating: hygieneRating ?? this.hygieneRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Pairs a [Stall] with its computed Haversine distance from the user.
class StallWithDistance {
  const StallWithDistance({
    required this.stall,
    required this.distanceKm,
  });

  final Stall stall;
  final double distanceKm;
}
