import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

// NEW Config Import
import 'package:mobileapp/config.dart';

enum ForgotPasswordStep {
  checkAccount,
  emailFound,
  noEmail,
  verifyOtp,
  resetPassword,
  manualRequest,
  requestSubmitted
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  var _currentStep = ForgotPasswordStep.checkAccount;
  final _studentNumberController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _messageController = TextEditingController();

  int _studentId = 0;
  String _email = '';
  String _referenceId = '';

  // Image files for verification
  File? _idImage;
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  // [UPDATED] Use Config
  final String _apiUrl = Config.forgotPasswordUrl;

  Future<void> _handleStep() async {
    switch (_currentStep) {
      case ForgotPasswordStep.checkAccount:
        _checkAccount();
        break;
      case ForgotPasswordStep.emailFound:
        _sendOtp();
        break;
      case ForgotPasswordStep.verifyOtp:
        _verifyOtp();
        break;
      case ForgotPasswordStep.resetPassword:
        _resetPassword();
        break;
      case ForgotPasswordStep.manualRequest:
        _submitManualRequest();
        break;
      case ForgotPasswordStep.noEmail:
      case ForgotPasswordStep.requestSubmitted:
        // No async action
        break;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- UPDATED: Camera Only Logic ---
  Future<void> _takePhoto(bool isId) async {
    try {
      // Force ImageSource.camera to prevent uploading edited photos from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 80, // Compress slightly to save data
      );
      
      if (image != null) {
        setState(() {
          if (isId) {
            _idImage = File(image.path);
          } else {
            _selfieImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError("Could not open camera. Please check permissions.");
    }
  }

  // --- API Calls ---

  Future<void> _checkAccount() async {
    showLoadingDialog(context, 'Checking Account...');
    try {
      final response = await http.post(Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'action': 'check_account',
            'student_number': _studentNumberController.text,
          }));
      if (mounted) Navigator.of(context).pop();
      final body = json.decode(response.body);

      if (body['status'] == 'email_found') {
        setState(() {
          _studentId = body['student_id'];
          _email = body['email'];
          _currentStep = ForgotPasswordStep.emailFound;
        });
      } else if (body['status'] == 'no_email') {
        setState(() {
          _studentId = body['student_id'];
          _currentStep = ForgotPasswordStep.noEmail;
        });
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('Connection Error: ${e.toString()}');
    }
  }

  Future<void> _sendOtp() async {
    showLoadingDialog(context, 'Sending Code...');
    try {
      final response = await http.post(Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'action': 'send_recovery_otp',
            'student_id': _studentId,
            'email': _email,
          }));
      if (mounted) Navigator.of(context).pop();
      final body = json.decode(response.body);

      if (body['status'] == 'otp_sent') {
        setState(() {
          _currentStep = ForgotPasswordStep.verifyOtp;
        });
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('Connection Error');
    }
  }

  Future<void> _verifyOtp() async {
    showLoadingDialog(context, 'Verifying...');
    try {
      final response = await http.post(Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'action': 'verify_recovery_otp',
            'student_id': _studentId,
            'otp': _otpController.text,
          }));
      if (mounted) Navigator.of(context).pop();
      final body = json.decode(response.body);

      if (body['status'] == 'success') {
        setState(() {
          _currentStep = ForgotPasswordStep.resetPassword;
        });
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('Connection Error');
    }
  }

  Future<void> _resetPassword() async {
    showLoadingDialog(context, 'Resetting Password...');
    try {
      final response = await http.post(Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'action': 'reset_password',
            'student_id': _studentId,
            'password': _passwordController.text,
          }));
      if (mounted) Navigator.of(context).pop();
      final body = json.decode(response.body);

      if (body['status'] == 'success') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: kPrimaryDark,
              title: const Text('Password Reset', style: TextStyle(color: kPrimaryGold)),
              content: const Text(
                  'Your password has been reset successfully. You can now log in.',
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login screen
                  },
                  child: const Text('OK', style: TextStyle(color: kPrimaryGold)),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('Connection Error');
    }
  }

  Future<void> _submitManualRequest() async {
    if (_idImage == null || _selfieImage == null) {
      _showError("Please take photos of both your ID and a Selfie.");
      return;
    }

    showLoadingDialog(context, 'Uploading & Submitting...');
    
    try {
      // Create Multipart Request for file upload
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      request.fields['action'] = 'submit_manual_request';
      request.fields['student_id'] = _studentId.toString();
      request.fields['message'] = _messageController.text;

      // Add ID Image
      var idFile = await http.MultipartFile.fromPath(
        'id_proof', 
        _idImage!.path,
      );
      request.files.add(idFile);

      // Add Selfie Image
      var selfieFile = await http.MultipartFile.fromPath(
        'selfie_proof', 
        _selfieImage!.path,
      );
      request.files.add(selfieFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (mounted) Navigator.of(context).pop(); // Pop loading

      final body = json.decode(response.body);

      if (body['status'] == 'success') {
        setState(() {
          _referenceId = body['reference_id'].toString();
          _currentStep = ForgotPasswordStep.requestSubmitted;
        });
      } else {
        _showError(body['message']);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showError('Submission failed: $e');
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildCurrentStepWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case ForgotPasswordStep.checkAccount:
        return _buildCheckAccount();
      case ForgotPasswordStep.emailFound:
        return _buildEmailFound();
      case ForgotPasswordStep.noEmail:
        return _buildNoEmail();
      case ForgotPasswordStep.verifyOtp:
        return _buildVerifyOtp();
      case ForgotPasswordStep.resetPassword:
        return _buildResetPassword();
      case ForgotPasswordStep.manualRequest:
        return _buildManualRequest();
      case ForgotPasswordStep.requestSubmitted:
        return _buildRequestSubmitted();
    }
  }

  Widget _buildCheckAccount() {
    return Column(
      key: const ValueKey('checkAccount'),
      children: [
        const Text(
          'Enter your Student Number to begin the recovery process.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildTextField(_studentNumberController, 'Student Number'),
        const SizedBox(height: 20),
        _buildButton('CONTINUE', _handleStep),
      ],
    ).animate().fadeIn();
  }

  Widget _buildEmailFound() {
    return Column(
      key: const ValueKey('emailFound'),
      children: [
        Text(
          'We found an email associated with your account:\n$_email',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildButton('SEND RECOVERY CODE', _handleStep),
        _buildTextButton('I don\'t have access to this email', () {
          setState(() {
            _currentStep = ForgotPasswordStep.noEmail;
          });
        }),
      ],
    ).animate().fadeIn();
  }

  Widget _buildNoEmail() {
    return Column(
      key: const ValueKey('noEmail'),
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
        const SizedBox(height: 20),
        const Text(
          'No Email on File',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'We do not have a verified email for this account. You must submit a manual recovery request to the admin.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildButton('REQUEST MANUAL RESET', () {
          setState(() {
            _currentStep = ForgotPasswordStep.manualRequest;
          });
        }),
      ],
    ).animate().fadeIn();
  }

  Widget _buildVerifyOtp() {
    return Column(
      key: const ValueKey('verifyOtp'),
      children: [
        Text(
          'Enter the 6-digit code sent to $_email',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Pinput(
          controller: _otpController,
          length: 6,
          defaultPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: const TextStyle(fontSize: 20, color: Colors.white),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildButton('VERIFY CODE', _handleStep),
      ],
    ).animate().fadeIn();
  }

  Widget _buildResetPassword() {
    return Column(
      key: const ValueKey('resetPassword'),
      children: [
        const Text(
          'Create a new password for your account.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildTextField(_passwordController, 'New Password', isPassword: true),
        const SizedBox(height: 20),
        _buildButton('RESET PASSWORD', _handleStep),
      ],
    ).animate().fadeIn();
  }

  // --- UPDATED MANUAL REQUEST UI ---
  Widget _buildManualRequest() {
    return Column(
      key: const ValueKey('manualRequest'),
      children: [
        const Text(
          'Identity Verification',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'For security, please take a LIVE photo of your ID and a Selfie. Uploads from gallery are disabled to prevent editing.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildTextField(_messageController,
            'Message (e.g., "I lost my email access, here are my proofs...")',
            maxLines: 3),
        const SizedBox(height: 20),
        
        // --- Image Pickers (Camera Only) ---
        Row(
          children: [
            Expanded(child: _buildImagePickerButton('Take ID Photo', _idImage, true)),
            const SizedBox(width: 15),
            Expanded(child: _buildImagePickerButton('Take Selfie', _selfieImage, false)),
          ],
        ),
        
        const SizedBox(height: 25),
        _buildButton('SUBMIT REQUEST', _handleStep),
      ],
    ).animate().fadeIn();
  }

  Widget _buildImagePickerButton(String label, File? imageFile, bool isId) {
    return GestureDetector(
      onTap: () => _takePhoto(isId), // Directly opens camera
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: imageFile != null ? kPrimaryGold : Colors.white30),
        ),
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    ),
                  )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: kPrimaryGold, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label, 
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestSubmitted() {
    return Column(
      key: const ValueKey('requestSubmitted'),
      children: [
        const Icon(Icons.check_circle_outline,
            color: Colors.greenAccent, size: 60),
        const SizedBox(height: 20),
        const Text(
          'Request Submitted',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Your request has been sent to the admin. Your Reference Number is:',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _referenceId,
          style: const TextStyle(
              color: kPrimaryGold, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Use the notification bell on the login screen to check your progress.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildButton('BACK TO LOGIN', () {
          Navigator.of(context).pop();
        }),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isPassword = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGold,
        foregroundColor: kPrimaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: kPrimaryGold)),
    );
  }
}