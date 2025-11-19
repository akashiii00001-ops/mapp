import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
        ChangeNotifierProvider(create: (_) => UserProvider()), 
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'PSU Digital Yearbook',
      theme: themeProvider.currentThemeData, 
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}