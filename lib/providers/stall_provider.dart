import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/firestore_stall_service.dart';
import 'package:streetbite/services/location_service.dart';
import 'package:streetbite/services/notification_service.dart';
import 'package:streetbite/utils/debouncer.dart';
import 'package:streetbite/utils/geohash_util.dart';

/// ViewModel managing geo-radius discovery, craving search, offers, and notifications.
class StallProvider extends ChangeNotifier {
  StallProvider({
    required FirestoreStallService stallService,
    required LocationService locationService,
  })  : _stallService = stallService,
        _locationService = locationService;

  final FirestoreStallService _stallService;
  final LocationService _locationService;
  final Debouncer _searchDebouncer =
      Debouncer(duration: AppSearchConfig.debounceDuration);

  StreamSubscription<List<Stall>>? _offerSubscription;
  final Map<String, String> _knownOfferKeys = <String, String>{};
  bool _initialOfferSnapshotSeen = false;

  List<StallWithDistance> _stalls = <StallWithDistance>[];
  final List<DiscountAlertItem> _discountAlerts = <DiscountAlertItem>[];
  double _userLat = AppGeoDefaults.defaultLatitude;
  double _userLng = AppGeoDefaults.defaultLongitude;
  String _locationStatus = 'Finding nearby stalls...';
  bool _isUsingFallbackLocation = true;

  double _radiusKm = AppGeoDefaults.defaultRadiusKm;
  String _cravingQuery = '';
  bool _openNowOnly = false;
  bool _offersOnly = false;
  StallSortOrder _sortOrder = StallSortOrder.distance;
  bool _isMapView = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<StallWithDistance> get stalls => List<StallWithDistance>.unmodifiable(_stalls);
  List<DiscountAlertItem> get discountAlerts =>
      List<DiscountAlertItem>.unmodifiable(_discountAlerts);
  int get unreadAlertCount =>
      _discountAlerts.where((item) => !item.isRead).length;

  double get userLat => _userLat;
  double get userLng => _userLng;
  String get locationStatus => _locationStatus;
  bool get isUsingFallbackLocation => _isUsingFallbackLocation;
  double get radiusKm => _radiusKm;
  String get cravingQuery => _cravingQuery;
  bool get openNowOnly => _openNowOnly;
  bool get offersOnly => _offersOnly;
  StallSortOrder get sortOrder => _sortOrder;
  bool get isMapView => _isMapView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await NotificationService.instance.requestPermission();

    final location = await _locationService.getCurrentLocation();
    _userLat = location.latitude;
    _userLng = location.longitude;
    _locationStatus = location.statusMessage;
    _isUsingFallbackLocation = location.isFallback;

    await loadStalls();
    _seedInitialOfferAlerts();
    _listenToLiveOfferUpdates();
  }

  void _seedInitialOfferAlerts() {
    for (final item in _stalls) {
      final stall = item.stall;
      if (stall.hasValidOffer) {
        final offer = stall.activeOffer!;
        _knownOfferKeys[stall.id] = _offerSignature(offer);
        _upsertAlert(stall: stall, offer: offer, markRead: false);
      }
    }
    notifyListeners();
  }

  void _listenToLiveOfferUpdates() {
    _offerSubscription?.cancel();
    _offerSubscription = _stallService.watchLiveStallOffers().listen((stalls) {
      final isFirst = !_initialOfferSnapshotSeen;
      _initialOfferSnapshotSeen = true;

      for (final stall in stalls) {
        if (!stall.hasValidOffer) {
          _knownOfferKeys.remove(stall.id);
          continue;
        }
        final offer = stall.activeOffer!;
        final signature = _offerSignature(offer);
        final previous = _knownOfferKeys[stall.id];
        if (previous != signature) {
          _knownOfferKeys[stall.id] = signature;
          _upsertAlert(stall: stall, offer: offer, markRead: false);
          if (!isFirst) {
            NotificationService.instance.showDiscountNotification(
              stall: stall,
              offer: offer,
            );
            syncStallUpdate(stall);
          }
        }
      }
      notifyListeners();
    });
  }

  String _offerSignature(StallOffer offer) =>
      '${offer.title}|${offer.discountPercent}|${offer.durationType.name}|${offer.expiresAt.toIso8601String()}';

  void _upsertAlert({
    required Stall stall,
    required StallOffer offer,
    required bool markRead,
  }) {
    _discountAlerts.removeWhere((item) => item.stallId == stall.id);
    _discountAlerts.insert(
      0,
      DiscountAlertItem(
        id: '${stall.id}-${offer.expiresAt.millisecondsSinceEpoch}',
        stallId: stall.id,
        stallName: stall.name,
        offer: offer,
        receivedAt: DateTime.now(),
        isRead: markRead,
      ),
    );
  }

  /// Triggers an immediate Android status-bar notification and adds an in-app alert.
  void notifyNewOfferPublished(Stall stall) {
    if (!stall.hasValidOffer) return;
    final offer = stall.activeOffer!;
    _knownOfferKeys[stall.id] = _offerSignature(offer);
    _upsertAlert(stall: stall, offer: offer, markRead: false);
    NotificationService.instance.showDiscountNotification(
      stall: stall,
      offer: offer,
    );
    syncStallUpdate(stall);
    notifyListeners();
  }

  void markAllAlertsRead() {
    for (var i = 0; i < _discountAlerts.length; i++) {
      _discountAlerts[i] = _discountAlerts[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  StallWithDistance? findStallById(String stallId) {
    for (final item in _stalls) {
      if (item.stall.id == stallId) return item;
    }
    return null;
  }

  Future<void> refreshLocationAndStalls() async {
    final location = await _locationService.getCurrentLocation();
    _userLat = location.latitude;
    _userLng = location.longitude;
    _locationStatus = location.statusMessage;
    _isUsingFallbackLocation = location.isFallback;
    await loadStalls();
  }

  Future<void> loadStalls() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stalls = await _stallService.fetchNearbyStalls(
        userLat: _userLat,
        userLng: _userLng,
        radiusKm: _radiusKm,
        cravingQuery: _cravingQuery,
        openNowOnly: _openNowOnly,
        offersOnly: _offersOnly,
        sortOrder: _sortOrder,
      );
    } catch (e) {
      debugPrint('Failed to load nearby stalls: $e');
      _errorMessage = 'Could not load nearby stalls. Pull down or tap retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Debounces text search (380ms) so Firestore queries don't fire per keystroke.
  void onSearchChanged(String query) {
    _cravingQuery = query;
    notifyListeners();
    _searchDebouncer.run(loadStalls);
  }

  void selectCravingChip(String tag) {
    final normalized = tag.trim();
    if (_cravingQuery.toLowerCase() == normalized.toLowerCase()) {
      _cravingQuery = '';
    } else {
      _cravingQuery = normalized;
    }
    _searchDebouncer.cancel();
    loadStalls();
  }

  void clearSearch() {
    _cravingQuery = '';
    _searchDebouncer.cancel();
    loadStalls();
  }

  void resetAllFilters() {
    _cravingQuery = '';
    _openNowOnly = false;
    _offersOnly = false;
    _radiusKm = AppGeoDefaults.maxRadiusKm;
    _searchDebouncer.cancel();
    loadStalls();
  }

  void updateRadiusPreview(double value) {
    _radiusKm = value.clamp(
      AppGeoDefaults.minRadiusKm,
      AppGeoDefaults.maxRadiusKm,
    );
    notifyListeners();
  }

  void commitRadiusKm(double value) {
    _radiusKm = value.clamp(
      AppGeoDefaults.minRadiusKm,
      AppGeoDefaults.maxRadiusKm,
    );
    loadStalls();
  }

  void toggleOpenNowOnly() {
    _openNowOnly = !_openNowOnly;
    loadStalls();
  }

  void toggleOffersOnly() {
    _offersOnly = !_offersOnly;
    loadStalls();
  }

  void setSortOrder(StallSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    loadStalls();
  }

  void setMapView(bool mapView) {
    if (_isMapView == mapView) return;
    _isMapView = mapView;
    notifyListeners();
  }

  /// Reflects vendor edits or live status/offer updates immediately in discovery results.
  void syncStallUpdate(Stall updated) {
    final dist = GeohashUtil.haversineDistanceKm(
      _userLat,
      _userLng,
      updated.latitude,
      updated.longitude,
    );
    final idx = _stalls.indexWhere((item) => item.stall.id == updated.id);
    if (idx != -1) {
      if ((_openNowOnly && !updated.isOpen) ||
          (_offersOnly && !updated.hasValidOffer) ||
          dist > _radiusKm) {
        _stalls.removeAt(idx);
      } else {
        _stalls[idx] = StallWithDistance(stall: updated, distanceKm: dist);
      }
      notifyListeners();
    } else if (dist <= _radiusKm &&
        (!_openNowOnly || updated.isOpen) &&
        (!_offersOnly || updated.hasValidOffer)) {
      loadStalls();
    }
  }

  void removeStall(String stallId) {
    _stalls.removeWhere((item) => item.stall.id == stallId);
    _discountAlerts.removeWhere((item) => item.stallId == stallId);
    notifyListeners();
  }

  Future<List<Review>> fetchReviews(String stallId) {
    return _stallService.fetchReviews(stallId);
  }

  Future<Stall?> submitReview(Review review) async {
    final updatedStall = await _stallService.addReview(review);
    if (updatedStall != null) {
      syncStallUpdate(updatedStall);
    }
    return updatedStall;
  }

  @override
  void dispose() {
    _offerSubscription?.cancel();
    _searchDebouncer.dispose();
    super.dispose();
  }
}
