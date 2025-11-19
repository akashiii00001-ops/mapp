import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/theme.dart';
import 'package:provider/provider.dart';

class ProgressStepper extends StatelessWidget {
  const ProgressStepper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final progress = authProvider.progress;
    final currentStep = authProvider.currentStep;

    // Calculate the width of the animated bar
    // We base it on the number of steps - 1
    double progressWidth = 0;
    if (progress > 0.25) {
      progressWidth = (MediaQuery.of(context).size.width - 64) * ((progress - 0.25) / 0.75);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
      child: Column(
        children: [
          // This Row creates the steps and the line
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // The background (grey) line
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // The foreground (gold) animated line
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 4,
                width: progressWidth,
                decoration: BoxDecoration(
                  color: kPrimaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // The step circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepCircle(
                    label: 'Login',
                    isActive: progress >= 0.25,
                    isCurrent: currentStep == AuthStep.login,
                  ),
                  _StepCircle(
                    label: 'Identity',
                    isActive: progress >= 0.5,
                    isCurrent: currentStep == AuthStep.identity,
                  ),
                  _StepCircle(
                    label: 'Email',
                    isActive: progress >= 0.75,
                    isCurrent: currentStep == AuthStep.email,
                  ),
                  _StepCircle(
                    label: 'Done',
                    isActive: progress >= 1.0,
                    isCurrent: currentStep == AuthStep.home,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepText('Login', isActive: progress >= 0.25),
              _StepText('Identity', isActive: progress >= 0.5),
              _StepText('Email', isActive: progress >= 0.75),
              _StepText('Done', isActive: progress >= 1.0),
            ],
          )
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCurrent;

  const _StepCircle({
    required this.label,
    required this.isActive,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 16 : 12,
      height: isCurrent ? 16 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? kPrimaryGold : Colors.grey[800],
        border: isCurrent ? Border.all(color: kPrimaryDark, width: 2) : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: kPrimaryGold.withOpacity(0.7),
                  blurRadius: 6,
                )
              ]
            : [],
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  final String text;
  final bool isActive;
  const _StepText(this.text, {required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? kPrimaryGold : Colors.grey[600],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}