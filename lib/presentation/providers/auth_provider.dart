import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:earnjoy/data/datasources/supabase_service.dart';

/// Manages authentication state (anonymous, email/password).
class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase;

  AuthProvider(this._supabase) {
    // Listen for auth state changes (e.g., session restore on app launch)
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  /// The currently signed-in Supabase user, or null if not authenticated.
  User? get authUser => _supabase.currentAuthUser;

  bool get isSignedIn => _supabase.isSignedIn;
  bool get isAnonymous => _supabase.isAnonymous;
  String? get email => authUser?.email;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _clearError() {
    _error = null;
  }

  // ─── Sign In Anonymous ────────────────────────────────────────────────────

  Future<bool> signInAnonymous() async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.signInAnonymous();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<bool> signUpWithEmail(String email, String password) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.signUpWithEmail(email, password);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<bool> signInWithEmail(String email, String password) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.signInWithEmail(email, password);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.signOut();
    } on AuthException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
