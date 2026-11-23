import 'package:streetbite/models/menu_item.dart';
import 'package:streetbite/models/review.dart';

/// Supported shopkeeper special discount windows.
enum OfferDurationType {
  hour,
  day,
  week,
  month;

  String get label => switch (this) {
        OfferDurationType.hour => 'Hourly Deal',
        OfferDurationType.day => 'Daily Special',
        OfferDurationType.week => 'Weekly Offer',
        OfferDurationType.month => 'Monthly Offer',
      };

  String get shortLabel => switch (this) {
        OfferDurationType.hour => 'Hourly',
        OfferDurationType.day => 'Daily',
        OfferDurationType.week => 'Weekly',
        OfferDurationType.month => 'Monthly',
      };

  static OfferDurationType fromName(String? raw) {
    return OfferDurationType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => OfferDurationType.day,
    );
  }
}

/// Limited-time discount or promo published by a street food vendor.
class StallOffer {
  const StallOffer({
    required this.title,
    required this.discountPercent,
    required this.durationType,
    required this.expiresAt,
    this.isActive = true,
  });

  final String title;
  final int discountPercent;
  final OfferDurationType durationType;
  final DateTime expiresAt;
  final bool isActive;

  bool get isCurrentlyValid => isActive && expiresAt.isAfter(DateTime.now());

  String get discountBadge =>
      discountPercent > 0 ? '$discountPercent% OFF' : 'SPECIAL DEAL';

  String get remainingTimeLabel {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'Ends in ${weeks}w ${diff.inDays % 7}d';
    }
    if (diff.inDays >= 1) {
      return 'Ends in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours >= 1) {
      return 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes >= 1) {
      return 'Ends in ${diff.inMinutes}m';
    }
    return 'Ending soon';
  }

  factory StallOffer.fromJson(Map<String, dynamic> json) {
    return StallOffer(
      title: (json['title'] as String?) ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      durationType:
          OfferDurationType.fromName(json['durationType'] as String?),
      expiresAt: Review.parseFlexibleDateTime(json['expiresAt']),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'discountPercent': discountPercent,
      'durationType': durationType.name,
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  StallOffer copyWith({
    String? title,
    int? discountPercent,
    OfferDurationType? durationType,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return StallOffer(
      title: title ?? this.title,
      discountPercent: discountPercent ?? this.discountPercent,
      durationType: durationType ?? this.durationType,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

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
    this.activeOffer,
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
  final StallOffer? activeOffer;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get overallRating => (tasteRating + hygieneRating) / 2.0;

  bool get hasValidOffer =>
      activeOffer != null && activeOffer!.isCurrentlyValid;

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
    StallOffer? activeOffer,
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
    if (activeOffer != null && activeOffer.isCurrentlyValid) {
      addTokens(activeOffer.title);
      addTokens(activeOffer.durationType.label);
      addTokens('discount offer deal');
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

    final rawOffer = json['activeOffer'];
    final StallOffer? parsedOffer = rawOffer is Map<String, dynamic>
        ? StallOffer.fromJson(rawOffer)
        : (rawOffer is Map
            ? StallOffer.fromJson(Map<String, dynamic>.from(rawOffer))
            : null);

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
      activeOffer: parsedOffer,
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
      'activeOffer': activeOffer?.toJson(),
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
    StallOffer? activeOffer,
    bool clearActiveOffer = false,
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
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
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
