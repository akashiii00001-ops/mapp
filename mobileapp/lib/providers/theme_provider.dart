import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currentThemeType = 'light'; // 'light', 'dark', 'psu'

  ThemeMode get themeMode => _themeMode;
  String get currentThemeType => _currentThemeType;

  void setTheme(String type) {
    _currentThemeType = type;
    if (type == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  ThemeData getTheme() {
    if (_currentThemeType == 'psu') {
      return _psuTheme;
    } else if (_currentThemeType == 'dark') {
      return ThemeData.dark(useMaterial3: true);
    }
    return ThemeData.light(useMaterial3: true);
  }

  // PSU Custom Theme (Blue & Yellow)
  static final ThemeData _psuTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF0033A0), // PSU Blue
    scaffoldBackgroundColor: const Color(0xFFFFFDD0), // Light Yellow (Cream)
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0033A0),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFD700), // PSU Gold/Yellow
      foregroundColor: Colors.black,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0033A0),
      primary: const Color(0xFF0033A0),
      secondary: const Color(0xFFFFD700),
      background: const Color(0xFFFFFDD0),
    ),
  );
}