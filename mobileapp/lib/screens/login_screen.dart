import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

// Imports from your existing project
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';

// NEW Config Import
import 'package:mobileapp/config.dart'; 

// Imports for the NEW login flow
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/screens/identity_verify_screen.dart';
import 'package:mobileapp/screens/email_2fa_screen.dart';
import 'package:mobileapp/screens/forgot_password_screen.dart';
import 'package:mobileapp/screens/account_status_screen.dart';


// RENAMED FROM UpgradedLoginScreen TO LoginScreen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Variables ---
  bool _obscureText = true;
  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Variables for UI animations ---
  bool _isLogoHovering = false;
  Offset _logoOffset = Offset.zero; // For parallax effect
  bool _isStudentNumberFocused = false;
  bool _isPasswordFocused = false;
  final FocusNode _studentNumberFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoginButtonHovering = false;

  @override
  void initState() {
    super.initState();
    // Listeners for focus changes to animate text fields
    _studentNumberFocus.addListener(() {
      setState(() {
        _isStudentNumberFocused = _studentNumberFocus.hasFocus;
      });
    });
    _passwordFocus.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocus.hasFocus;
      });
    });

    // Set the auth progress to the first step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setStep(AuthStep.login);
    });
  }

  @override
  void dispose() {
    // Dispose all controllers and nodes
    _studentNumberController.dispose();
    _passwordController.dispose();
    _studentNumberFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  //
  // --- --------------------------------- ---
  // ---   NEW MODIFIED LOGIN LOGIC      ---
  // --- --------------------------------- ---
  //
  Future<void> _handleLogin() async {
    // Set progress step to login
    context.read<AuthProvider>().setStep(AuthStep.login);

    showLoadingDialog(context, 'Logging in...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'student_number': _studentNumberController.text,
          'password': _passwordController.text,
        }),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      final responseBody = json.decode(response.body);
      final status = responseBody['status'];
      final message = responseBody['message'] ?? 'An error occurred';
      
      if (status == 'security_questions_required') {
        final studentId = responseBody['student_id'];
        if (mounted) {
          Navigator.of(context).push( // Use push, not pushReplacement
            MaterialPageRoute(
              builder: (context) => IdentityVerifyScreen(
                studentId: studentId,
              ),
            ),
          );
        }
      } else if (status == 'email_2fa_required') {
        final studentId = responseBody['student_id'];
        final studentEmail = responseBody['student_email'];
        if (mounted) {
          Navigator.of(context).push( // Use push
            MaterialPageRoute(
              builder: (context) => Email2FAScreen(
                studentId: studentId,
                studentEmail: studentEmail,
              ),
            ),
          );
        }
      } else {
        if (mounted) _showErrorDialog(message);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Could not connect to the server. Please check XAMPP. ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // FIX: Updated withOpacity to withValues
        backgroundColor: kPrimaryDark.withValues(alpha: 0.9),
        title: const Text('Login Error', style: TextStyle(color: Colors.redAccent)),
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
  // --- --------------------------------- ---
  // ---   END OF NEW LOGIN LOGIC        ---
  // --- --------------------------------- ---

  //
  // --- ------------------------------------------ ---
  // --- NEW NOTIFICATION BUTTON & RECOVERY LOGIC ---
  // --- ------------------------------------------ ---
  //
  Future<void> _checkRecoveryStatus() async {
    if (_studentNumberController.text.isEmpty) {
      _showNotificationDialog(
        'Info',
        'Please enter your Student Number first to check for notifications.',
      );
      return;
    }

    showLoadingDialog(context, 'Checking Status...');
    
    // [UPDATED] Use Config
    final url = Uri.parse(Config.recoveryStatusUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'student_number': _studentNumberController.text}),
      );

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      final responseBody = json.decode(response.body);
      String title = 'Notification';
      String message = 'No pending requests found.';

      if (responseBody['status'] == 'found') {
        String requestStatus = responseBody['request_status'];
        String adminNotes = responseBody['admin_notes'] ?? '';

        switch (requestStatus) {
          case 'pending_admin':
            title = 'Request Pending';
            message =
                'Your account recovery request is still pending admin approval. Please check back later.';
            break;
          case 'approved':
            title = 'Request Approved!';
            message =
                'Your account password has been reset. You can now log in using your Student Number as your password.';
            break;
          case 'denied':
            title = 'Request Denied';
            message =
                'Your account recovery request was denied. Reason: $adminNotes';
            break;
          default:
            message = 'You have no active account recovery notifications.';
            break;
        }
      }
      _showNotificationDialog(title, message, requestStatus: responseBody['request_status']);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showNotificationDialog('Connection Error', 'Could not connect to the server.');
    }
  }

  void _showNotificationDialog(String title, String message, {String? requestStatus}) {
    Color titleColor = kPrimaryGold;
    if (requestStatus == 'approved') {
      titleColor = Colors.greenAccent;
    } else if (requestStatus == 'denied') {
      titleColor = Colors.redAccent;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // FIX: Updated withOpacity to withValues
        backgroundColor: kPrimaryDark.withValues(alpha: 0.9),
        title: Text(title, style: TextStyle(color: titleColor)),
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
  // --- ------------------------------------------ ---
  // ---      END OF NEW NOTIFICATION LOGIC       ---
  // --- ------------------------------------------ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Layer 1: Animated Lottie Background ---
          Lottie.asset(
            'assets/animations/particles_background.json',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          // --- Layer 2: Gradient Overlay ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // FIX: Updated withOpacity to withValues
                  kPrimaryDark.withValues(alpha: 0.8),
                  kPrimaryDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // --- Layer 3: Notification Button ---
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Your new "Account Status" page button
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white70, size: 28),
                    onPressed: () {
                       Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              const AccountStatusScreen(),
                        ));
                    },
                    tooltip: 'Check Request Status Page',
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active_outlined,
                        color: kPrimaryGold, size: 28),
                    onPressed: _checkRecoveryStatus,
                    tooltip: 'Check Recovery Status',
                  ),
                ],
              ),
            ),
          ),

          // --- Layer 4: Login Content ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Animated Logo ---
                  _buildAnimatedLogo(),
                  const SizedBox(height: 20),
                  const Text(
                    "Digital Yearbook",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    "Pangasinan State University",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Glassmorphism Card ---
                  _buildGlassCard(
                    child: Column(
                      children: [
                        // --- Student Number Field ---
                        _buildTextField(
                          controller: _studentNumberController,
                          focusNode: _studentNumberFocus,
                          isFocused: _isStudentNumberFocused,
                          hint: 'Student Number',
                          icon: FontAwesomeIcons.userGraduate,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        
                        // --- Password Field ---
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isFocused: _isPasswordFocused,
                          hint: 'Password',
                          icon: FontAwesomeIcons.lock,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(), // Allow login on "done"
                        ),
                        const SizedBox(height: 24),
                        
                        // --- Login Button ---
                        _buildLoginButton(),
                        
                        // --- Forgot Password Button ---
                        TextButton(
                          onPressed: () {
                            // Navigate to the new flow
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ));
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //
  // --- --------------------- ---
  // --- NEW ANIMATED WIDGETS ---
  // --- --------------------- ---
  //

  Widget _buildAnimatedLogo() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isLogoHovering = true),
      onExit: (_) {
        setState(() {
          _isLogoHovering = false;
          _logoOffset = Offset.zero; // Reset offset
        });
      },
      onHover: (event) {
        // Calculate parallax movement (max 10px)
        final screenCenter = MediaQuery.of(context).size.width / 2;
        final moveX = (event.position.dx - screenCenter) / screenCenter * 10;
        setState(() {
          _logoOffset = Offset(moveX, 0); // Only X-axis parallax
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        // 1. Tilt and Parallax
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // 3D perspective
          ..rotateY(_isLogoHovering ? 0.1 : 0) // Tilt
          ..translate(_logoOffset.dx, _logoOffset.dy), // Parallax
        transformAlignment: Alignment.center,
        // 2. Glow
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _isLogoHovering
              ? [
                  BoxShadow(
                    // FIX: Updated withOpacity to withValues
                    color: kPrimaryGold.withValues(alpha: 0.7),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        // Use a Hero widget for the transition from splash screen
        child: Hero(
          tag: "lion_logo", // Same tag as in splash_screen.dart
          child: Image.asset(
            'assets/images/psu_lion_logo.png', // Your existing logo
            height: 120,
            width: 120,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // FIX: Updated withOpacity to withValues
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              // FIX: Updated withOpacity to withValues
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputAction textInputAction = TextInputAction.none,
    Function(String)? onSubmitted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // 3. Focus Shadow
        boxShadow: isFocused
            ? [
                BoxShadow(
                  // FIX: Updated withOpacity to withValues
                  color: kPrimaryGold.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword ? _obscureText : false,
        style: const TextStyle(color: Colors.white),
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          // FIX: Updated withOpacity to withValues
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          filled: true,
          // FIX: Updated withOpacity to withValues
          fillColor: Colors.black.withValues(alpha: 0.3),
          // 1. Animated Icon
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: AnimatedTheme(
              data: ThemeData(
                iconTheme: IconThemeData(
                  color: isFocused ? kPrimaryGold : Colors.white70,
                  size: 20,
                ),
              ),
              duration: const Duration(milliseconds: 300),
              child: Icon(icon),
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? FontAwesomeIcons.eyeSlash
                        : FontAwesomeIcons.eye,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          // 2. Border Color Transition
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            // FIX: Updated withOpacity to withValues
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: kPrimaryGold, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isLoginButtonHovering = true),
      onExit: (_) => setState(() => _isLoginButtonHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // 3. Hover Glow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isLoginButtonHovering
              ? [
                  BoxShadow(
                    // FIX: Updated withOpacity to withValues
                    color: kPrimaryGold.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: kPrimaryGold,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            // 1. Ripple
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              HapticFeedback.lightImpact(); // Haptic feedback
              _handleLogin(); // Your existing logic
            },
            // 2. Scale Animation (via hover state)
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              transform: Matrix4.identity()
                ..scale(_isLoginButtonHovering ? 1.05 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}