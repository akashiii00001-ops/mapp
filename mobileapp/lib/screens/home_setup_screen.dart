import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/screens/home_screen.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/progress_stepper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeSetupScreen extends StatefulWidget {
  const HomeSetupScreen({super.key});

  @override
  State<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends State<HomeSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Set the progress bar to the final 'home' step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setStep(AuthStep.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressStepper(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/golden_lion_shimmer.json', // Use your shimmer animation
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Setup Complete!',
                      style: TextStyle(color: kPrimaryGold, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome to the PSU Digital Yearbook.\nYour journey starts now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGold,
                        foregroundColor: kPrimaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      onPressed: () {
                        // Reset the auth provider
                        context.read<AuthProvider>().setStep(AuthStep.login);
                        // Navigate to the real home screen, clearing all setup screens
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text('START EXPLORING', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}