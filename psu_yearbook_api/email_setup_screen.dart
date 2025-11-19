import 'package:flutter/material.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/screens/home_setup_screen.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';
import 'package:mobileapp/widgets/progress_stepper.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

// NEW Config Import
import 'package:mobileapp/config.dart';

class EmailSetupScreen extends StatefulWidget {
  final int studentId;
  const EmailSetupScreen({super.key, required this.studentId});

  @override
  State<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends State<EmailSetupScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setStep(AuthStep.email);
    });
  }

  Future<void> _sendOtp() async {
    showLoadingDialog(context, 'Sending Code...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.email2faUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'action': 'send_otp',
          'student_id': widget.studentId,
          'email': _emailController.text,
        }),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        setState(() {
          _isOtpSent = true;
        });
      } else {
        if (mounted) _showErrorDialog(responseBody['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Connection error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    showLoadingDialog(context, 'Verifying Code...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.email2faUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'action': 'verify_otp',
          'student_id': widget.studentId,
          'email': _emailController.text,
          'otp': _otpController.text,
        }),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading

      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const HomeSetupScreen(),
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
        title: const Text('Error', style: TextStyle(color: Colors.redAccent)),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isOtpSent
                      ? _buildOtpEntry()
                      : _buildEmailEntry(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailEntry() {
    return Column(
      key: const ValueKey('email_entry'),
      children: [
        const Icon(Icons.email_outlined, color: kPrimaryGold, size: 80),
        const SizedBox(height: 20),
        const Text(
          'Set Up Your Email',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'This email will be used for account recovery and 2-factor authentication.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your personal email',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryGold, width: 2),
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
          onPressed: _sendOtp,
          child: const Text('SEND VERIFICATION CODE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.5),
    );
  }

  Widget _buildOtpEntry() {
    return Column(
      key: const ValueKey('otp_entry'),
      children: [
        const Icon(Icons.shield_outlined, color: kPrimaryGold, size: 80),
        const SizedBox(height: 20),
        const Text(
          'Enter Your Code',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a code to:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 30),
        Pinput(
          controller: _otpController,
          length: 6,
          onCompleted: (pin) => _verifyOtp(),
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
          onPressed: _verifyOtp,
          child: const Text('VERIFY & FINISH SETUP', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isOtpSent = false;
              _otpController.clear();
            });
          },
          child: const Text('Change Email Address', style: TextStyle(color: kPrimaryGold)),
        )
      ].animate(interval: 100.ms).fadeIn(duration: 300.ms).slideX(begin: 0.5),
    );
  }
}