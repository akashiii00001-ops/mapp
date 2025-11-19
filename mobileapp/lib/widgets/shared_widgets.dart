import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- BACKGROUND WRAPPER ---
class GradientBackground extends StatelessWidget {
  final Widget child;
  final String themeMode; // 'light', 'dark', 'gradient'

  const GradientBackground({super.key, required this.child, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (themeMode == 'dark') {
      decoration = const BoxDecoration(color: Color(0xFF0F172A)); // Slate 900
    } else if (themeMode == 'gradient') {
      decoration = const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)], // Indigo, Purple, Pink
        ),
      );
    } else {
      decoration = const BoxDecoration(color: Color(0xFFF8FAFC)); // Slate 50
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: decoration,
      child: child,
    );
  }
}

// --- GLASS CONTAINER ---
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isDark;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF1E293B).withValues(alpha: 0.8) 
              : Colors.white.withValues(alpha: 0.8),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- 3D CARD ---
class Card3D extends StatelessWidget {
  final Widget child;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double delay;
  final bool isDark;

  const Card3D({
    super.key,
    required this.child,
    this.imageUrl,
    this.onTap,
    this.delay = 0,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        width: 300,
        // CRITICAL FIX: Force height to fill parent so Spacer() inside child works
        height: double.infinity, 
        child: Stack(
          children: [
            // Glow effect behind
            Positioned.fill(
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 10))
                  ],
                ),
              ),
            ),
            // Actual Card
            Positioned.fill( // CRITICAL FIX: Use Positioned.fill to ensure ClipRRect fills the Stack
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.withValues(alpha: 0.2),
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        // CRITICAL FIX: Expand the content area to allow Spacer() to work
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay.toInt())).slideY(begin: 0.1, end: 0),
    );
  }
}

// --- BADGE ---
class CustomBadge extends StatelessWidget {
  final String text;
  final String type; // 'primary', 'success', 'warning'

  const CustomBadge({super.key, required this.text, this.type = 'primary'});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case 'success':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'warning':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }
}