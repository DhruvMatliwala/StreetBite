import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/firestore_stall_service.dart';
import 'package:streetbite/services/location_service.dart';
import 'package:streetbite/services/storage_service.dart';

/// ViewModel managing the Vendor Portal: live open/closed toggle, discounts, menus, photos, GPS pin.
class VendorProvider extends ChangeNotifier {
  VendorProvider({
    required FirestoreStallService stallService,
    required StorageService storageService,
    required LocationService locationService,
  })  : _stallService = stallService,
        _storageService = storageService,
        _locationService = locationService;

  final FirestoreStallService _stallService;
  final StorageService _storageService;
  final LocationService _locationService;

  List<Stall> _vendorStalls = <Stall>[];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  List<Stall> get vendorStalls => List<Stall>.unmodifiable(_vendorStalls);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;

  int get openStallCount => _vendorStalls.where((s) => s.isOpen).length;

  Future<void> loadVendorStalls(String vendorId) async {
    if (vendorId.isEmpty) {
      _vendorStalls = <Stall>[];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vendorStalls = await _stallService.fetchVendorStalls(vendorId);
    } catch (e) {
      debugPrint('Failed to load vendor stalls: $e');
      _errorMessage = 'Unable to load your stalls right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistically toggles Open/Closed status with Firestore persistence.
  Future<bool> toggleOpenStatus(
    Stall stall,
    bool nextOpen, {
    ValueChanged<Stall>? onSynced,
  }) async {
    final idx = _vendorStalls.indexWhere((s) => s.id == stall.id);
    final updated = stall.copyWith(
      isOpen: nextOpen,
      updatedAt: DateTime.now(),
    );

    if (idx != -1) {
      _vendorStalls[idx] = updated;
      notifyListeners();
    }

    try {
      await _stallService.toggleStallOpenStatus(
        stallId: stall.id,
        isOpen: nextOpen,
      );
      onSynced?.call(updated);
      return true;
    } catch (e) {
      debugPrint('Failed to toggle stall status: $e');
      if (idx != -1) {
        _vendorStalls[idx] = stall;
        _errorMessage = 'Failed to update stall status. Please retry.';
        notifyListeners();
      }
      return false;
    }
  }

  /// Publishes or clears a limited-time Hourly/Daily/Weekly/Monthly offer.
  Future<Stall?> updateStallOffer(
    Stall stall,
    StallOffer? offer, {
    ValueChanged<Stall>? onSynced,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _stallService.updateStallOffer(
        stall: stall,
        offer: offer,
      );
      final idx = _vendorStalls.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        _vendorStalls[idx] = updated;
      }
      onSynced?.call(updated);
      return updated;
    } catch (e) {
      debugPrint('Failed to update stall offer: $e');
      _errorMessage = 'Could not update offer. Please retry.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Stall?> saveStall(
    Stall stall, {
    ValueChanged<Stall>? onSynced,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final saved = await _stallService.upsertStall(stall);
      final idx = _vendorStalls.indexWhere((s) => s.id == saved.id);
      if (idx == -1) {
        _vendorStalls.insert(0, saved);
      } else {
        _vendorStalls[idx] = saved;
      }
      onSynced?.call(saved);
      return saved;
    } catch (e) {
      debugPrint('Failed to save stall: $e');
      _errorMessage = 'Could not save stall details. Check your connection.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStall(
    String stallId, {
    ValueChanged<String>? onDeleted,
  }) async {
    try {
      await _stallService.deleteStall(stallId);
      _vendorStalls.removeWhere((s) => s.id == stallId);
      onDeleted?.call(stallId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete stall: $e');
      _errorMessage = 'Could not delete stall.';
      notifyListeners();
      return false;
    }
  }

  Future<String?> pickAndUploadPhoto({
    required ImageSource source,
    required String vendorId,
    required String stallId,
  }) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _storageService.pickAndUploadStallImage(
        source: source,
        vendorId: vendorId,
        stallId: stallId,
      );
    } catch (e) {
      debugPrint('Photo upload failed: $e');
      _errorMessage = 'Photo upload failed. Try another image.';
      return null;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<LocationResult> resolveCurrentLocation() {
    return _locationService.getCurrentLocation();
  }
}
