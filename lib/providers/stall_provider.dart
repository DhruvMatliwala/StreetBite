import 'package:flutter/foundation.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/firestore_stall_service.dart';
import 'package:streetbite/services/location_service.dart';
import 'package:streetbite/utils/debouncer.dart';
import 'package:streetbite/utils/geohash_util.dart';

/// ViewModel managing hyper-local geo-radius discovery, craving search, and reviews.
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

  List<StallWithDistance> _stalls = <StallWithDistance>[];
  double _userLat = AppGeoDefaults.defaultLatitude;
  double _userLng = AppGeoDefaults.defaultLongitude;
  String _locationStatus = 'Finding nearby stalls...';
  bool _isUsingFallbackLocation = true;

  double _radiusKm = AppGeoDefaults.defaultRadiusKm;
  String _cravingQuery = '';
  bool _openNowOnly = false;
  StallSortOrder _sortOrder = StallSortOrder.distance;
  bool _isMapView = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<StallWithDistance> get stalls => List<StallWithDistance>.unmodifiable(_stalls);
  double get userLat => _userLat;
  double get userLng => _userLng;
  String get locationStatus => _locationStatus;
  bool get isUsingFallbackLocation => _isUsingFallbackLocation;
  double get radiusKm => _radiusKm;
  String get cravingQuery => _cravingQuery;
  bool get openNowOnly => _openNowOnly;
  StallSortOrder get sortOrder => _sortOrder;
  bool get isMapView => _isMapView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final location = await _locationService.getCurrentLocation();
    _userLat = location.latitude;
    _userLng = location.longitude;
    _locationStatus = location.statusMessage;
    _isUsingFallbackLocation = location.isFallback;

    await loadStalls();
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

  /// Reflects vendor edits or live status toggles immediately in discovery results.
  void syncStallUpdate(Stall updated) {
    final dist = GeohashUtil.haversineDistanceKm(
      _userLat,
      _userLng,
      updated.latitude,
      updated.longitude,
    );
    final idx = _stalls.indexWhere((item) => item.stall.id == updated.id);
    if (idx != -1) {
      if ((_openNowOnly && !updated.isOpen) || dist > _radiusKm) {
        _stalls.removeAt(idx);
      } else {
        _stalls[idx] = StallWithDistance(stall: updated, distanceKm: dist);
      }
      notifyListeners();
    } else if (dist <= _radiusKm && (!_openNowOnly || updated.isOpen)) {
      loadStalls();
    }
  }

  void removeStall(String stallId) {
    _stalls.removeWhere((item) => item.stall.id == stallId);
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
    _searchDebouncer.dispose();
    super.dispose();
  }
}
