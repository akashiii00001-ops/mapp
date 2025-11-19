import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/widgets/shared_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkContent;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black)),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        themeMode: theme.currentMode,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              isDark: isDark,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 20)]
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset('assets/images/psu_lion_logo.png', color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text("PSU Yearbook App", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Version 2.5.0", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "The PSU Yearbook App connects alumni, celebrates achievements, and fosters a lifelong community. Built with the latest Flutter technologies.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("© 2025 PSU Alumni Association", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}