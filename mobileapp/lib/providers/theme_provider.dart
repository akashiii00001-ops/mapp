import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Modes: 'light', 'dark', 'gradient'
  String _currentMode = 'light';

  String get currentMode => _currentMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMode = prefs.getString('theme_mode') ?? 'light';
    notifyListeners();
  }

  ThemeData getTheme() {
    if (_currentMode == 'light') {
      return ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: Colors.blue,
        // Add other light theme properties if needed
      );
    } else {
      // Dark & Gradient share the same basic text styling (white text)
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.indigo,
      );
    }
  }

  // Used by the toggle button in Home Screen
  void cycleTheme() {
    if (_currentMode == 'light') {
      setTheme('dark');
    } else if (_currentMode == 'dark') {
      setTheme('gradient');
    } else {
      setTheme('light');
    }
  }

  // FIXED: Added this method for the Settings Screen dropdown
  Future<void> setTheme(String mode) async {
    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    notifyListeners();
  }
  
  bool get isDarkContent => _currentMode != 'light';
}