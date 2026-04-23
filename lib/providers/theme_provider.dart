import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.light;
  ThemeType _selectedThemeType = ThemeType.light;
  bool _useDynamicTheme = false;
  SpendingMood _currentMood = SpendingMood.good;

  AppTheme get currentTheme => _currentTheme;
  ThemeType get selectedThemeType => _selectedThemeType;
  bool get useDynamicTheme => _useDynamicTheme;
  SpendingMood get currentMood => _currentMood;

  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeTypeString = prefs.getString('theme_type') ?? 'light';
    _selectedThemeType = ThemeType.values.firstWhere(
      (type) => type.toString().split('.').last == themeTypeString,
      orElse: () => ThemeType.light,
    );
    _useDynamicTheme = prefs.getBool('use_dynamic_theme') ?? false;
    _currentMood = SpendingMood.values.firstWhere(
      (mood) => mood.toString().split('.').last == prefs.getString('spending_mood'),
      orElse: () => SpendingMood.good,
    );
    _updateCurrentTheme();
  }

  Future<void> setTheme(ThemeType themeType) async {
    _selectedThemeType = themeType;
    _useDynamicTheme = false;
    await _saveThemePreferences();
    _updateCurrentTheme();
  }

  Future<void> setDynamicTheme(bool enabled) async {
    _useDynamicTheme = enabled;
    await _saveThemePreferences();
    _updateCurrentTheme();
  }

  Future<void> _saveThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_type', _selectedThemeType.toString().split('.').last);
    await prefs.setBool('use_dynamic_theme', _useDynamicTheme);
    await prefs.setString('spending_mood', _currentMood.toString().split('.').last);
  }

  void _updateCurrentTheme() {
    if (_useDynamicTheme) {
      _currentTheme = _themeForMood(_currentMood);
    } else {
      _currentTheme = _themeForType(_selectedThemeType);
    }
    notifyListeners();
  }

  AppTheme _themeForType(ThemeType type) {
    switch (type) {
      case ThemeType.dark:
        return AppTheme.dark;
      case ThemeType.teal:
        return AppTheme.teal;
      case ThemeType.purple:
        return AppTheme.purple;
      case ThemeType.ocean:
        return AppTheme.ocean;
      case ThemeType.sunset:
        return AppTheme.sunset;
      case ThemeType.forest:
        return AppTheme.forest;
      case ThemeType.midnight:
        return AppTheme.midnight;
      default:
        return AppTheme.light;
    }
  }

  AppTheme _themeForMood(SpendingMood mood) {
    switch (mood) {
      case SpendingMood.excellent:
        return AppTheme.light;
      case SpendingMood.good:
        return AppTheme.teal;
      case SpendingMood.warning:
        return AppTheme.sunset;
      case SpendingMood.danger:
        return AppTheme.dark;
    }
  }

  Color getMoodColor() {
    switch (_currentMood) {
      case SpendingMood.excellent:
        return Colors.green;
      case SpendingMood.good:
        return Colors.blue;
      case SpendingMood.warning:
        return Colors.orange;
      case SpendingMood.danger:
        return Colors.red;
    }
  }

  Future<void> updateSpendingMood() async {
    // Default behavior: keep the current mood until spending analysis is available.
    _currentMood = SpendingMood.good;
    _updateCurrentTheme();
  }

  IconData getMoodIcon() {
    switch (_currentMood) {
      case SpendingMood.excellent:
        return Icons.sentiment_very_satisfied;
      case SpendingMood.good:
        return Icons.sentiment_satisfied;
      case SpendingMood.warning:
        return Icons.sentiment_neutral;
      case SpendingMood.danger:
        return Icons.sentiment_dissatisfied;
    }
  }

  String getMoodDescription() {
    switch (_currentMood) {
      case SpendingMood.excellent:
        return 'Excellent spending control';
      case SpendingMood.good:
        return 'Spending is on track';
      case SpendingMood.warning:
        return 'Approaching your budget limit';
      case SpendingMood.danger:
        return 'Over budget — take action';
    }
  }
}
