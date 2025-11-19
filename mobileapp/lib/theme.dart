import 'package:flutter/material.dart';

const Color kPrimaryDark = Color(0xFF000020);
const Color kPrimaryGold = Color(0xFFD4AF37);
const Color psuBlue = Color(0xFF01579B);
const Color psuLightYellow = Color(0xFFFFFDE7);

// 1. Dark Theme (Your Existing)
ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: kPrimaryGold,
    scaffoldBackgroundColor: kPrimaryDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: kPrimaryGold),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryGold,
      secondary: psuBlue,
      background: kPrimaryDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGold,
        foregroundColor: kPrimaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );
}

// 2. Light Theme
ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: psuBlue,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: psuBlue),
      titleTextStyle: TextStyle(color: psuBlue, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.light(
      primary: psuBlue,
      secondary: kPrimaryGold,
      background: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: psuBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );
}

// 3. PSU Theme Mode
ThemeData buildPSUTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: psuBlue,
    scaffoldBackgroundColor: psuLightYellow, 
    appBarTheme: const AppBarTheme(
      backgroundColor: psuBlue,
      elevation: 4,
      iconTheme: IconThemeData(color: kPrimaryGold),
      titleTextStyle: TextStyle(color: kPrimaryGold, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.light(
      primary: psuBlue,
      secondary: kPrimaryGold,
      background: psuLightYellow,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: psuBlue,
        foregroundColor: kPrimaryGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}