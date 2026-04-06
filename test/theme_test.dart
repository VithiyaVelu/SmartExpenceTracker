import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/models/theme.dart';
import '../lib/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('Theme creation and properties', () {
    // Test light theme
    expect(AppTheme.light.type, ThemeType.light);
    expect(AppTheme.light.name, 'Light');
    expect(AppTheme.light.primaryColor, Colors.teal);

    // Test dark theme
    expect(AppTheme.dark.type, ThemeType.dark);
    expect(AppTheme.dark.name, 'Dark');

    // Test all themes list
    expect(AppTheme.allThemes.length, 8); // light, dark, teal, purple, ocean, sunset, forest, midnight
  });

  test('Dynamic theme creation', () {
    // Test excellent mood (green theme)
    final excellentTheme = AppTheme.createDynamicTheme(SpendingMood.excellent);
    expect(excellentTheme.primaryColor, Colors.green);

    // Test danger mood (red theme)
    final dangerTheme = AppTheme.createDynamicTheme(SpendingMood.danger);
    expect(dangerTheme.primaryColor, Colors.red);
  });

  test('Theme provider initialization', () async {
    final themeProvider = ThemeProvider();
    await Future.delayed(const Duration(milliseconds: 100)); // Wait for initialization

    expect(themeProvider.selectedThemeType, ThemeType.light);
    expect(themeProvider.useDynamicTheme, false);
    expect(themeProvider.currentMood, SpendingMood.good);
  });

  test('Theme switching', () async {
    final themeProvider = ThemeProvider();
    await Future.delayed(const Duration(milliseconds: 100));

    // Switch to dark theme
    await themeProvider.setTheme(ThemeType.dark);
    expect(themeProvider.selectedThemeType, ThemeType.dark);
    expect(themeProvider.currentTheme.type, ThemeType.dark);

    // Enable dynamic theme
    await themeProvider.setDynamicTheme(true);
    expect(themeProvider.useDynamicTheme, true);
    expect(themeProvider.currentTheme.primaryColor, Colors.teal); // Good mood = teal
  });
}