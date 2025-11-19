import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 20)],
                      ),
                      child: Image.asset('assets/images/psu_lion_logo.png', height: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "PSU Yearbook App",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Version 2.5.0",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "The PSU Yearbook App connects alumni, celebrates achievements, and fosters a lifelong community. Built with the latest technologies to provide a seamless and modern experience.\n\n© 2025 PSU Alumni Association.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
      ),
    );
  }
}