import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/screens/email_setup_screen.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';
import 'package:mobileapp/widgets/progress_stepper.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

// NEW Config Import
import 'package:mobileapp/config.dart';

class IdentityVerifyScreen extends StatefulWidget {
  final int studentId;
  const IdentityVerifyScreen({super.key, required this.studentId});

  @override
  State<IdentityVerifyScreen> createState() => _IdentityVerifyScreenState();
}

class _IdentityVerifyScreenState extends State<IdentityVerifyScreen> {
  final _motherLnameController = TextEditingController();
  final _barangayController = TextEditingController();
  final _courseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the progress bar to the 'identity' step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setStep(AuthStep.identity);
    });
  }

  Future<void> _verifyIdentity() async {
    showLoadingDialog(context, 'Verifying Identity...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.verifySecurityUrl); 
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'student_id': widget.studentId,
          'mother_lname': _motherLnameController.text,
          'barangay': _barangayController.text,
          'course': _courseController.text,
        }),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'email_setup_required') {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EmailSetupScreen(studentId: widget.studentId),
            ),
          );
        }
      } else {
        if (mounted) _showErrorDialog(responseBody['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Connection error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPrimaryDark.withOpacity(0.9),
        title: const Text('Verification Error', style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: kPrimaryGold)),
          ),
        ],
      ),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.security_outlined, color: kPrimaryGold, size: 80),
                    const SizedBox(height: 20),
                    const Text(
                      'Identity Verification',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'To protect your account, please answer these security questions from your student record.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(_motherLnameController, "Mother's Maiden Last Name"),
                    const SizedBox(height: 16),
                    _buildTextField(_barangayController, 'Barangay'),
                    const SizedBox(height: 16),
                    _buildTextField(_courseController, 'Your Course (e.g., Bachelor of Science in Information Technology)'),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGold,
                        foregroundColor: kPrimaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      onPressed: _verifyIdentity,
                      child: const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryGold, width: 2),
        ),
      ),
    );
  }
}