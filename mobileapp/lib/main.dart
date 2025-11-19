import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/user_provider.dart'; // Ensure you have this
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'PSU Digital Yearbook',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getTheme(),
      home: const SplashScreen(),
    );
  }
}