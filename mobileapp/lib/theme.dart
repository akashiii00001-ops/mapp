import 'package:flutter/material.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryDark = Color(0xFF0F172A); 
const Color kPrimaryGold = Color(0xFFD4AF37); 

// Keeping these for legacy compatibility if needed, 
// but we are moving to the Dark theme.
const Color psuLightYellow = Color(0xFFFFFDE7);
const Color psuBlue = Color(0xFF01579B);

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: kPrimaryGold,
    scaffoldBackgroundColor: kPrimaryDark,
    
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryGold,
      secondary: kPrimaryGold,
      surface: kPrimaryDark, 
      onPrimary: kPrimaryDark, 
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: kPrimaryGold),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGold,
        foregroundColor: kPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x4D000000), // Black with ~30% opacity
      hintStyle: const TextStyle(color: Color(0xB3FFFFFF)), // White with ~70% opacity
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0x4DFFFFFF)), // White with ~30% opacity
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kPrimaryGold, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    ),
  );
}