import 'package:flutter/material.dart';

// --- NEW MODERN THEME ---
// A deep, academic blue for a premium feel
const Color kPrimaryDark = Color(0xFF000020); 
// A rich, metallic gold for highlights and buttons
const Color kPrimaryGold = Color(0xFFD4AF37); 

// --- YOUR EXISTING PSU COLORS (Still available if needed) ---
const Color psuLightYellow = Color(0xFFFFFDE7);
const Color psuSemiLightBlue = Color(0xFFB3E5FC);
const Color psuGolden = Color(0xFFFFD700);
const Color psuBlue = Color(0xFF01579B);

// --- THE MISSING buildTheme METHOD ---
ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: kPrimaryGold,
    scaffoldBackgroundColor: kPrimaryDark,
    
    // Define the color scheme for the app
    colorScheme: ColorScheme.dark(
      primary: kPrimaryGold,
      secondary: kPrimaryGold,
      background: kPrimaryDark,
      surface: kPrimaryDark,
      onPrimary: kPrimaryDark, // Text on gold buttons
      onBackground: Colors.white, // Text on dark background
      onSurface: Colors.white,
      error: Colors.redAccent,
    ),

    // --- App Bar Theme ---
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

    // --- Text Theme ---
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
      titleMedium: TextStyle(color: Colors.white, fontSize: 18),
      titleSmall: TextStyle(color: Colors.white, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
      labelLarge: TextStyle( // For button text
        color: kPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // --- Button Theme ---
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

    // --- Text Field Theme (for Login Screen & others) ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kPrimaryGold, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    ),
  );
}