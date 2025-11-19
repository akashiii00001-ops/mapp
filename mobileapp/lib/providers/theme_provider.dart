import 'package:flutter/material.dart';
import 'package:mobileapp/theme.dart';

enum AppThemeMode { light, dark, psu }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentMode = AppThemeMode.light; // Default

  AppThemeMode get currentMode => _currentMode;

  ThemeData get currentThemeData {
    switch (_currentMode) {
      case AppThemeMode.dark:
        return buildTheme(); // From your existing theme.dart (refactored below)
      case AppThemeMode.psu:
        return buildPSUTheme(); 
      case AppThemeMode.light:
      default:
        return buildLightTheme(); 
    }
  }

  void setMode(AppThemeMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
}