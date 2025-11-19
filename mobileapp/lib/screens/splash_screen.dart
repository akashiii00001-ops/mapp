import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const UpgradedLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Lottie.asset(
            'assets/animations/particles_background.json',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: Hero(
              tag: "lion_logo", // This must match the tag in LoginScreen
              child: Image.asset(
                'assets/images/psu_lion_logo.png',
                width: 150,
              ),
            ).animate().fadeIn(duration: 1500.ms).scale(begin: const Offset(0.5, 0.5)),
          ),
        ],
      ),
    );
  }
}