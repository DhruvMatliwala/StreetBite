import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/mock_stall_data.dart';
import 'package:streetbite/utils/geohash_util.dart';

enum StallSortOrder { distance, rating }

/// Dual-mode service querying Cloud Firestore with graceful local sample fallback.
class FirestoreStallService {
  FirestoreStallService({
    required this.isDemoMode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final bool isDemoMode;
  final FirebaseFirestore? _firestore;

  final List<Stall> _demoStalls = MockStallData.buildInitialStalls();
  final Map<String, List<Review>> _demoReviews =
      MockStallData.buildInitialReviews();
  bool _hasLocalWrites = false;

  CollectionReference<Map<String, dynamic>> get _stallsRef {
    final db = _firestore ?? FirebaseFirestore.instance;
    return db.collection('stalls');
  }

  /// Queries stalls inside [radiusKm] using geohash bounds + Haversine filter.
  Future<List<StallWithDistance>> fetchNearbyStalls({
    required double userLat,
    required double userLng,
    required double radiusKm,
    String cravingQuery = '',
    bool openNowOnly = false,
    StallSortOrder sortOrder = StallSortOrder.distance,
  }) async {
    final List<Stall> candidateStalls;

    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      candidateStalls = List<Stall>.from(_demoStalls);
    } else {
      final merged = <String, Stall>{};
      try {
        final ranges = GeohashUtil.queryBounds(userLat, userLng, radiusKm);
        final futures = ranges.map((range) {
          Query<Map<String, dynamic>> query = _stallsRef;
          if (openNowOnly) {
            query = query.where('isOpen', isEqualTo: true);
          }
          return query
              .where('geohash', isGreaterThanOrEqualTo: range.start)
              .where('geohash', isLessThanOrEqualTo: range.end)
              .get();
        });

        final snapshots = await Future.wait(futures);
        for (final snapshot in snapshots) {
          for (final doc in snapshot.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            merged[doc.id] = Stall.fromJson(data);
          }
        }
      } catch (e) {
        debugPrint('Firestore query fallback to sample stalls: $e');
      }

      if (merged.isEmpty || _hasLocalWrites) {
        for (final stall in _demoStalls) {
          merged.putIfAbsent(stall.id, () => stall);
        }
      }
      candidateStalls = merged.values.toList();
    }

    final normalizedQuery = cravingQuery.trim().toLowerCase();
    final matched = <StallWithDistance>[];

    for (final stall in candidateStalls) {
      if (openNowOnly && !stall.isOpen) continue;

      final distanceKm = GeohashUtil.haversineDistanceKm(
        userLat,
        userLng,
        stall.latitude,
        stall.longitude,
      );
      if (distanceKm > radiusKm) continue;

      if (normalizedQuery.isNotEmpty &&
          !_matchesCraving(stall, normalizedQuery)) {
        continue;
      }

      matched.add(StallWithDistance(stall: stall, distanceKm: distanceKm));
    }

    matched.sort((a, b) {
      switch (sortOrder) {
        case StallSortOrder.distance:
          return a.distanceKm.compareTo(b.distanceKm);
        case StallSortOrder.rating:
          final ratingCmp =
              b.stall.overallRating.compareTo(a.stall.overallRating);
          return ratingCmp != 0
              ? ratingCmp
              : a.distanceKm.compareTo(b.distanceKm);
      }
    });

    return matched;
  }

  /// Fetches stalls owned by [vendorId] for the Vendor Portal.
  Future<List<Stall>> fetchVendorStalls(String vendorId) async {
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      return _localVendorStalls(vendorId);
    }

    try {
      final snapshot = await _stallsRef
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('updatedAt', descending: true)
          .get();

      final live = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Stall.fromJson(data);
      }).toList();

      if (live.isNotEmpty) return live;
    } catch (e) {
      debugPrint('Vendor Firestore query fallback: $e');
    }

    return _localVendorStalls(vendorId);
  }

  List<Stall> _localVendorStalls(String vendorId) {
    final owned = _demoStalls
        .where((stall) => stall.vendorId == vendorId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return owned;
  }

  /// Immediately updates a stall's Open/Closed status in Firestore or local fallback.
  Future<void> toggleStallOpenStatus({
    required String stallId,
    required bool isOpen,
  }) async {
    final now = DateTime.now();
    if (isDemoMode) {
      _updateLocalStallStatus(stallId, isOpen, now);
      return;
    }

    try {
      await _stallsRef.doc(stallId).update(<String, dynamic>{
        'isOpen': isOpen,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('Toggle status fallback to local state: $e');
      _hasLocalWrites = true;
      _updateLocalStallStatus(stallId, isOpen, now);
    }
  }

  void _updateLocalStallStatus(String stallId, bool isOpen, DateTime now) {
    final index = _demoStalls.indexWhere((s) => s.id == stallId);
    if (index != -1) {
      _demoStalls[index] = _demoStalls[index].copyWith(
        isOpen: isOpen,
        updatedAt: now,
      );
    }
  }

  /// Creates or updates a stall document and returns the persisted [Stall].
  Future<Stall> upsertStall(Stall stall) async {
    final now = DateTime.now();
    final geohash = GeohashUtil.encode(stall.latitude, stall.longitude);
    final searchableItems = Stall.buildSearchableTokens(
      name: stall.name,
      menuItems: stall.menuItems,
      crowdTags: stall.crowdTags,
    );

    final isCreate = stall.id.isEmpty;
    final docId = isCreate
        ? (isDemoMode
            ? 'stall-${now.millisecondsSinceEpoch}'
            : _stallsRef.doc().id)
        : stall.id;

    final prepared = stall.copyWith(
      id: docId,
      geohash: geohash,
      searchableItems: searchableItems,
      createdAt: isCreate ? now : stall.createdAt,
      updatedAt: now,
    );

    if (isDemoMode) {
      _upsertLocalStall(prepared);
      return prepared;
    }

    try {
      final payload = _stallToFirestoreMap(prepared);
      if (isCreate) {
        await _stallsRef.doc(docId).set(payload);
      } else {
        await _stallsRef.doc(docId).update(payload);
      }
      return prepared;
    } catch (e) {
      debugPrint('Upsert stall fallback to local state: $e');
      _hasLocalWrites = true;
      _upsertLocalStall(prepared);
      return prepared;
    }
  }

  void _upsertLocalStall(Stall prepared) {
    final index = _demoStalls.indexWhere((s) => s.id == prepared.id);
    if (index == -1) {
      _demoStalls.insert(0, prepared);
    } else {
      _demoStalls[index] = prepared;
    }
  }

  Future<void> deleteStall(String stallId) async {
    if (isDemoMode) {
      _demoStalls.removeWhere((s) => s.id == stallId);
      return;
    }
    try {
      await _stallsRef.doc(stallId).delete();
    } catch (e) {
      debugPrint('Delete stall fallback to local state: $e');
      _hasLocalWrites = true;
      _demoStalls.removeWhere((s) => s.id == stallId);
    }
  }

  Future<List<Review>> fetchReviews(String stallId) async {
    if (isDemoMode) {
      return _localReviews(stallId);
    }

    try {
      final snapshot = await _stallsRef
          .doc(stallId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final live = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();
      if (live.isNotEmpty) return live;
    } catch (e) {
      debugPrint('Fetch reviews fallback: $e');
    }

    return _localReviews(stallId);
  }

  List<Review> _localReviews(String stallId) {
    final reviews = _demoReviews[stallId] ?? <Review>[];
    return List<Review>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Adds a community review and updates aggregate taste/hygiene ratings.
  Future<Stall?> addReview(Review review) async {
    final now = DateTime.now();

    if (isDemoMode) {
      return _addLocalReview(review, now);
    }

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final stallRef = _stallsRef.doc(review.stallId);
      final reviewRef = stallRef.collection('reviews').doc();

      return await db.runTransaction<Stall?>((transaction) async {
        final stallSnap = await transaction.get(stallRef);
        if (!stallSnap.exists || stallSnap.data() == null) return null;

        final data = Map<String, dynamic>.from(stallSnap.data()!);
        data['id'] = stallSnap.id;
        final existing = Stall.fromJson(data);

        final nextCount = existing.reviewCount + 1;
        final nextTaste =
            ((existing.tasteRating * existing.reviewCount) +
                    review.tasteRating) /
                nextCount;
        final nextHygiene =
            ((existing.hygieneRating * existing.reviewCount) +
                    review.hygieneRating) /
                nextCount;

        transaction.set(reviewRef, <String, dynamic>{
          'stallId': review.stallId,
          'authorUid': review.authorUid,
          'authorName': review.authorName,
          'tasteRating': review.tasteRating,
          'hygieneRating': review.hygieneRating,
          'comment': review.comment,
          'createdAt': Timestamp.fromDate(now),
        });

        transaction.update(stallRef, <String, dynamic>{
          'tasteRating': double.parse(nextTaste.toStringAsFixed(2)),
          'hygieneRating': double.parse(nextHygiene.toStringAsFixed(2)),
          'reviewCount': nextCount,
          'updatedAt': Timestamp.fromDate(now),
        });

        return existing.copyWith(
          tasteRating: double.parse(nextTaste.toStringAsFixed(2)),
          hygieneRating: double.parse(nextHygiene.toStringAsFixed(2)),
          reviewCount: nextCount,
          updatedAt: now,
        );
      });
    } catch (e) {
      debugPrint('Add review fallback to local state: $e');
      _hasLocalWrites = true;
      return _addLocalReview(review, now);
    }
  }

  Stall? _addLocalReview(Review review, DateTime now) {
    final list = _demoReviews.putIfAbsent(review.stallId, () => <Review>[]);
    final saved = review.copyWith(
      id: 'rev-${now.millisecondsSinceEpoch}',
      createdAt: now,
    );
    list.insert(0, saved);

    final stallIdx = _demoStalls.indexWhere((s) => s.id == review.stallId);
    if (stallIdx == -1) return null;
    final existing = _demoStalls[stallIdx];
    final nextCount = existing.reviewCount + 1;
    final nextTaste =
        ((existing.tasteRating * existing.reviewCount) + review.tasteRating) /
            nextCount;
    final nextHygiene =
        ((existing.hygieneRating * existing.reviewCount) +
                review.hygieneRating) /
            nextCount;
    final updated = existing.copyWith(
      tasteRating: double.parse(nextTaste.toStringAsFixed(2)),
      hygieneRating: double.parse(nextHygiene.toStringAsFixed(2)),
      reviewCount: nextCount,
      updatedAt: now,
    );
    _demoStalls[stallIdx] = updated;
    return updated;
  }

  bool _matchesCraving(Stall stall, String query) {
    if (stall.name.toLowerCase().contains(query)) return true;
    if (stall.description.toLowerCase().contains(query)) return true;
    if (stall.address.toLowerCase().contains(query)) return true;
    for (final token in stall.searchableItems) {
      if (token.toLowerCase().contains(query)) return true;
    }
    for (final item in stall.menuItems) {
      if (item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query)) {
        return true;
      }
    }
    for (final tag in stall.crowdTags) {
      if (tag.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  Map<String, dynamic> _stallToFirestoreMap(Stall stall) {
    return <String, dynamic>{
      'vendorId': stall.vendorId,
      'name': stall.name,
      'description': stall.description,
      'address': stall.address,
      'latitude': stall.latitude,
      'longitude': stall.longitude,
      'geohash': stall.geohash,
      'isOpen': stall.isOpen,
      'operatingHours': stall.operatingHours,
      'bannerImageUrl': stall.bannerImageUrl,
      'galleryUrls': stall.galleryUrls,
      'menuItems': stall.menuItems.map((m) => m.toJson()).toList(),
      'searchableItems': stall.searchableItems,
      'crowdTags': stall.crowdTags,
      'tasteRating': stall.tasteRating,
      'hygieneRating': stall.hygieneRating,
      'reviewCount': stall.reviewCount,
      'createdAt': Timestamp.fromDate(stall.createdAt),
      'updatedAt': Timestamp.fromDate(stall.updatedAt),
    };
  }
}
