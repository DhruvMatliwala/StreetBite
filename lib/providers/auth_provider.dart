import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streetbite/services/mock_stall_data.dart';

/// Manages user authentication (Firebase Auth + fallback local session) and app theme.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.isDemoMode}) {
    if (isDemoMode) {
      _uid = MockStallData.demoVendorId;
      _displayName = 'Dhruv (Demo Vendor)';
      _email = 'demo@streetbite.app';
    } else {
      _syncFromFirebaseUser(FirebaseAuth.instance.currentUser);
    }
  }

  final bool isDemoMode;

  String? _uid;
  String _displayName = 'StreetBite Foodie';
  String _email = '';
  bool _isLocalSession = false;
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  String? get uid => _uid;
  String get effectiveVendorId =>
      _uid ?? (isDemoMode ? MockStallData.demoVendorId : '');
  String get displayName => _displayName;
  String get email => _email;
  bool get isLocalSession => _isLocalSession;
  bool get isAuthenticated => isDemoMode || _uid != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInAnonymously() async {
    if (isDemoMode) {
      _uid = MockStallData.demoVendorId;
      _displayName = 'Dhruv (Demo Vendor)';
      _email = 'demo@streetbite.app';
      _isLocalSession = true;
      notifyListeners();
      return true;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _syncFromFirebaseUser(cred.user);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_shouldFallbackLocally(e.code)) {
        _activateLocalSession(
          uid: MockStallData.demoVendorId,
          displayName: 'Guest Vendor',
          email: '',
        );
        return true;
      }
      _errorMessage = e.message ?? 'Guest sign-in failed.';
      return false;
    } catch (_) {
      _activateLocalSession(
        uid: MockStallData.demoVendorId,
        displayName: 'Guest Vendor',
        email: '',
      );
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || trimmedEmail.length < 5) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    if (isDemoMode) {
      _activateLocalSession(
        uid: MockStallData.demoVendorId,
        displayName: trimmedEmail.split('@').first,
        email: trimmedEmail,
      );
      return true;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      _syncFromFirebaseUser(cred.user);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_shouldFallbackLocally(e.code)) {
        _activateLocalSession(
          uid: MockStallData.demoVendorId,
          displayName: trimmedEmail.split('@').first,
          email: trimmedEmail,
        );
        return true;
      }
      _errorMessage = e.message ?? 'Sign-in failed.';
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected error during sign-in.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.length < 2) {
      _errorMessage = 'Please enter your name (at least 2 characters).';
      notifyListeners();
      return false;
    }
    if (!trimmedEmail.contains('@') || trimmedEmail.length < 5) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    if (isDemoMode) {
      _activateLocalSession(
        uid: MockStallData.demoVendorId,
        displayName: trimmedName,
        email: trimmedEmail,
      );
      return true;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      await cred.user?.updateDisplayName(trimmedName);
      await cred.user?.reload();
      _syncFromFirebaseUser(FirebaseAuth.instance.currentUser);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_shouldFallbackLocally(e.code)) {
        _activateLocalSession(
          uid: MockStallData.demoVendorId,
          displayName: trimmedName,
          email: trimmedEmail,
        );
        return true;
      }
      _errorMessage = e.message ?? 'Account creation failed.';
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected error during registration.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (isDemoMode) {
      return;
    }
    _setLoading(true);
    try {
      if (!_isLocalSession) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('Sign-out notice: $e');
    } finally {
      _uid = null;
      _displayName = 'StreetBite Foodie';
      _email = '';
      _isLocalSession = false;
      _errorMessage = null;
      _setLoading(false);
    }
  }

  bool _shouldFallbackLocally(String code) {
    return code == 'operation-not-allowed' ||
        code == 'configuration-not-found' ||
        code == 'admin-restricted-operation';
  }

  void _activateLocalSession({
    required String uid,
    required String displayName,
    required String email,
  }) {
    _uid = uid;
    _displayName = displayName;
    _email = email;
    _isLocalSession = true;
    _errorMessage = null;
  }

  void _syncFromFirebaseUser(User? user) {
    _isLocalSession = false;
    if (user == null) {
      _uid = null;
      _displayName = 'StreetBite Foodie';
      _email = '';
    } else {
      _uid = user.uid;
      _displayName = (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : (user.isAnonymous ? 'Guest Vendor' : (user.email ?? 'Vendor'));
      _email = user.email ?? '';
    }
    _errorMessage = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }
}
