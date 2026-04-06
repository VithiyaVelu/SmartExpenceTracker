import 'package:flutter/material.dart';

enum ThemeType {
  light,
  dark,
  teal,
  purple,
  ocean,
  sunset,
  forest,
  midnight,
  dynamic, // Changes based on spending mood
}

enum SpendingMood {
  excellent, // Under budget, green theme
  good,      // On track, default theme
  warning,   // Approaching budget, yellow theme
  danger,    // Over budget, red theme
}

class AppTheme {
  final ThemeType type;
  final String name;
  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;

  const AppTheme({
    required this.type,
    required this.name,
    required this.themeData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
  });

  // Light Theme
  static AppTheme light = AppTheme(
    type: ThemeType.light,
    name: 'Light',
    primaryColor: Colors.teal,
    secondaryColor: Colors.tealAccent,
    accentColor: Colors.teal.shade700,
    backgroundColor: const Color(0xFFF4F7F9),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Dark Theme
  static AppTheme dark = AppTheme(
    type: ThemeType.dark,
    name: 'Dark',
    primaryColor: Colors.teal.shade300,
    secondaryColor: Colors.tealAccent,
    accentColor: Colors.teal.shade100,
    backgroundColor: const Color(0xFF121212),
    surfaceColor: const Color(0xFF1E1E1E),
    errorColor: Colors.redAccent,
    successColor: Colors.greenAccent,
    warningColor: Colors.orangeAccent,
    themeData: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Teal Theme
  static AppTheme teal = AppTheme(
    type: ThemeType.teal,
    name: 'Teal',
    primaryColor: Colors.teal,
    secondaryColor: Colors.tealAccent,
    accentColor: Colors.teal.shade700,
    backgroundColor: const Color(0xFFE0F2F1),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE0F2F1),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Purple Theme
  static AppTheme purple = AppTheme(
    type: ThemeType.purple,
    name: 'Purple',
    primaryColor: Colors.purple,
    secondaryColor: Colors.purpleAccent,
    accentColor: Colors.purple.shade700,
    backgroundColor: const Color(0xFFF3E5F5),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3E5F5),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Ocean Theme
  static AppTheme ocean = AppTheme(
    type: ThemeType.ocean,
    name: 'Ocean',
    primaryColor: Colors.blue,
    secondaryColor: Colors.lightBlue,
    accentColor: Colors.blue.shade800,
    backgroundColor: const Color(0xFFE3F2FD),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Sunset Theme
  static AppTheme sunset = AppTheme(
    type: ThemeType.sunset,
    name: 'Sunset',
    primaryColor: Colors.orange,
    secondaryColor: Colors.deepOrange,
    accentColor: Colors.orange.shade800,
    backgroundColor: const Color(0xFFFFF3E0),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.deepOrange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF3E0),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Forest Theme
  static AppTheme forest = AppTheme(
    type: ThemeType.forest,
    name: 'Forest',
    primaryColor: Colors.green,
    secondaryColor: Colors.lightGreen,
    accentColor: Colors.green.shade800,
    backgroundColor: const Color(0xFFE8F5E8),
    surfaceColor: Colors.white,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
    themeData: ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFE8F5E8),
      cardColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Midnight Theme
  static AppTheme midnight = AppTheme(
    type: ThemeType.midnight,
    name: 'Midnight',
    primaryColor: Colors.indigo,
    secondaryColor: Colors.indigoAccent,
    accentColor: Colors.indigo.shade900,
    backgroundColor: const Color(0xFF0D0D0D),
    surfaceColor: const Color(0xFF1A1A1A),
    errorColor: Colors.redAccent,
    successColor: Colors.greenAccent,
    warningColor: Colors.orangeAccent,
    themeData: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      cardColor: const Color(0xFF1A1A1A),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    ),
  );

  // Get all available themes
  static List<AppTheme> get allThemes => [
    light,
    dark,
    teal,
    purple,
    ocean,
    sunset,
    forest,
    midnight,
  ];

  // Get theme by type
  static AppTheme getThemeByType(ThemeType type) {
    return allThemes.firstWhere(
      (theme) => theme.type == type,
      orElse: () => light,
    );
  }

  // Create dynamic theme based on spending mood
  static AppTheme createDynamicTheme(SpendingMood mood) {
    switch (mood) {
      case SpendingMood.excellent:
        return forest; // Green theme for excellent spending
      case SpendingMood.good:
        return teal; // Default good theme
      case SpendingMood.warning:
        return sunset; // Orange theme for warning
      case SpendingMood.danger:
        return AppTheme( // Red theme for danger
          type: ThemeType.dynamic,
          name: 'Dynamic (Danger)',
          primaryColor: Colors.red,
          secondaryColor: Colors.redAccent,
          accentColor: Colors.red.shade800,
          backgroundColor: const Color(0xFFFFEBEE),
          surfaceColor: Colors.white,
          errorColor: Colors.red,
          successColor: Colors.green,
          warningColor: Colors.orange,
          themeData: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFEBEE),
            cardColor: Colors.white,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
    }
  }
}