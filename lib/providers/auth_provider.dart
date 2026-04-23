import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  String _handleAuthError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('password must be at least 6 characters')) {
      return 'Password must be at least 6 characters';
    }

    if (message.contains('invalid email or password')) {
      return 'Invalid email or password';
    }

    return 'Something went wrong. Please try again.';
  }

  // LOGIN
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool success = await _authService.login(email, password);

      if (success) {
        _isAuthenticated = true;
      } else {
        _errorMessage = _handleAuthError('invalid email or password');
      }
    } catch (e) {
      _errorMessage = _handleAuthError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // REGISTER
  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      await _authService.register(email, password);
      _isAuthenticated = true;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // LOGOUT
  Future<void> signOut() async {
    _isAuthenticated = false;
    notifyListeners();
  }

  // 👉 ADD THIS HERE (your missing method)
  Future<void> skipAuth() async {
    _isAuthenticated = true;
    notifyListeners();
  }
}
