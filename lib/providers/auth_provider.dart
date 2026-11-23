import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streetbite/services/mock_stall_data.dart';

/// Manages user authentication (Firebase Auth or Demo fallback) and app theme.
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
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  String? get uid => _uid;
  String get effectiveVendorId =>
      _uid ?? (isDemoMode ? MockStallData.demoVendorId : '');
  String get displayName => _displayName;
  String get email => _email;
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

  Future<void> signInAnonymously() async {
    if (isDemoMode) {
      _uid = MockStallData.demoVendorId;
      _displayName = 'Dhruv (Demo Vendor)';
      _email = 'demo@streetbite.app';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      _syncFromFirebaseUser(cred.user);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Guest sign-in failed.';
    } catch (_) {
      _errorMessage = 'Unable to sign in right now.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (isDemoMode) {
      _uid = MockStallData.demoVendorId;
      _email = email.trim();
      _displayName = email.split('@').first;
      notifyListeners();
      return true;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _syncFromFirebaseUser(cred.user);
      return true;
    } on FirebaseAuthException catch (e) {
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
    if (isDemoMode) {
      _uid = MockStallData.demoVendorId;
      _email = email.trim();
      _displayName = displayName.trim();
      notifyListeners();
      return true;
    }

    _setLoading(true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
      _syncFromFirebaseUser(FirebaseAuth.instance.currentUser);
      return true;
    } on FirebaseAuthException catch (e) {
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
      await FirebaseAuth.instance.signOut();
      _uid = null;
      _displayName = 'StreetBite Foodie';
      _email = '';
    } finally {
      _setLoading(false);
    }
  }

  void _syncFromFirebaseUser(User? user) {
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
