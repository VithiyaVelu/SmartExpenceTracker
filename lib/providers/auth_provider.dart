import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasSkippedAuth = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasSkippedAuth => _hasSkippedAuth;
  String? get errorMessage => _errorMessage;
  bool get firebaseAvailable => _authService.isFirebaseInitialized;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthPreferences();

    if (_authService.isFirebaseInitialized) {
      _isAuthenticated = _authService.currentUser != null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAuthPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSkippedAuth = prefs.getBool('has_skipped_auth') ?? false;
  }

  Future<void> _saveAuthPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_skipped_auth', _hasSkippedAuth);
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isAuthenticated = true;
      _hasSkippedAuth = false;
      await _saveAuthPreferences();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email, password, name);
      _isAuthenticated = true;
      _hasSkippedAuth = false;
      await _saveAuthPreferences();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authService.isFirebaseInitialized) {
        await _authService.signOut();
      }
      _isAuthenticated = false;
      _hasSkippedAuth = false;
      await _saveAuthPreferences();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> skipAuth() async {
    _hasSkippedAuth = true;
    _isAuthenticated = false;
    await _saveAuthPreferences();
    notifyListeners();
  }

  Future<void> syncToCloud() async {
    if (!_authService.isFirebaseInitialized) {
      throw Exception(
        'Firebase is not initialized. Cloud sync is unavailable.',
      );
    }
    if (!_isAuthenticated) {
      throw Exception('You must be signed in to sync data.');
    }
    // TODO: Implement real sync logic once cloud syncing is available.
  }
}
