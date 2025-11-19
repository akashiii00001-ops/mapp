import 'package:flutter/material.dart';
import 'package:mobileapp/screens/home_screen.dart'; // Your main app screen
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// NEW Config Import
import 'package:mobileapp/config.dart';

class Email2FAScreen extends StatefulWidget {
  final int studentId;
  final String studentEmail;

  const Email2FAScreen({
    super.key,
    required this.studentId,
    required this.studentEmail,
  });

  @override
  State<Email2FAScreen> createState() => _Email2FAScreenState();
}

class _Email2FAScreenState extends State<Email2FAScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verify2FA() async {
    showLoadingDialog(context, 'Verifying...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.email2faUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'action': 'verify_otp', // Re-using this action
          'student_id': widget.studentId,
          'otp': _otpController.text,
          'email': widget.studentEmail // Pass this along
        }),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        if (mounted) {
          // Navigate to the *real* home screen, bypassing setup
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
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
      appBar: AppBar(
        title: const Text('Verify Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, color: kPrimaryGold, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Check Your Email',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a verification code to:\n${widget.studentEmail}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Pinput(
                controller: _otpController,
                length: 6,
                onCompleted: (pin) => _verify2FA(),
                defaultPinTheme: PinTheme(
                  width: 56,
                  height: 56,
                  textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: kPrimaryGold),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGold,
                  foregroundColor: kPrimaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: _verify2FA,
                child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}