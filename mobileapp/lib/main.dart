import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/screens/splash_screen.dart'; 
import 'package:mobileapp/theme.dart'; // This import is now correct
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSU Digital Yearbook',
      theme: buildTheme(), // <-- Removed (Brightness.dark)
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Start with the Splash Screen
    );
  }
}