import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mobileapp/theme.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';
import 'package:mobileapp/config.dart'; 
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/user_provider.dart'; 

import 'package:mobileapp/screens/home_screen.dart';
import 'package:mobileapp/screens/identity_verify_screen.dart';
import 'package:mobileapp/screens/email_2fa_screen.dart';
import 'package:mobileapp/screens/forgot_password_screen.dart';
import 'package:mobileapp/screens/account_status_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  final TextEditingController _studentNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogoHovering = false;
  Offset _logoOffset = Offset.zero; 
  bool _isStudentNumberFocused = false;
  bool _isPasswordFocused = false;
  final FocusNode _studentNumberFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoginButtonHovering = false;

  @override
  void initState() {
    super.initState();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().setStep(AuthStep.login);
    });
  }

  @override
  void dispose() {
    _studentNumberController.dispose();
    _passwordController.dispose();
    _studentNumberFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    context.read<AuthProvider>().setStep(AuthStep.login);
    showLoadingDialog(context, 'Logging in...');
    
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

      if (mounted) Navigator.of(context).pop(); 

      if (response.statusCode != 200) {
        _showErrorDialog('Server returned error ${response.statusCode}');
        return;
      }

      final responseBody = json.decode(response.body);
      final status = responseBody['status'];
      final message = responseBody['message'] ?? 'An error occurred';
      
      if (status == 'error') {
        if (mounted) _showErrorDialog(message);
        return;
      }

      if (responseBody.containsKey('student_id')) {
        String fullName = "Student";
        if (responseBody['fname'] != null) {
          fullName = "${responseBody['fname']} ${responseBody['lname']}";
        }
        
        int batch = 0;
        if (responseBody['batch_year'] != null) {
          batch = int.tryParse(responseBody['batch_year'].toString()) ?? 0;
        }

        if (mounted) {
          await Provider.of<UserProvider>(context, listen: false).setUser(
            int.parse(responseBody['student_id'].toString()),
            _studentNumberController.text,
            fullName,
            batch,
          );
        }
      }

      if (status == 'security_questions_required') {
        final studentId = responseBody['student_id'];
        if (mounted) {
          Navigator.of(context).push( 
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
          Navigator.of(context).push( 
            MaterialPageRoute(
              builder: (context) => Email2FAScreen(
                studentId: studentId,
                studentEmail: studentEmail,
              ),
            ),
          );
        }
      } else {
         if (mounted) {
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
         }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Could not connect to the server. Please check Config URL. ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _checkRecoveryStatus() async {
    if (_studentNumberController.text.isEmpty) {
      _showNotificationDialog(
        'Info',
        'Please enter your Student Number first to check for notifications.',
      );
      return;
    }

    showLoadingDialog(context, 'Checking Status...');
    
    final url = Uri.parse(Config.recoveryStatusUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'student_number': _studentNumberController.text}),
      );

      if (mounted) Navigator.of(context).pop(); 

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Lottie.asset(
            'assets/animations/particles_background.json',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: kPrimaryDark),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryDark.withValues(alpha: 0.8),
                  kPrimaryDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _studentNumberController,
                          focusNode: _studentNumberFocus,
                          isFocused: _isStudentNumberFocused,
                          hint: 'Student Number',
                          icon: FontAwesomeIcons.userGraduate,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isFocused: _isPasswordFocused,
                          hint: 'Password',
                          icon: FontAwesomeIcons.lock,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(), 
                        ),
                        const SizedBox(height: 24),
                        
                        _buildLoginButton(),
                        
                        TextButton(
                          onPressed: () {
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

  Widget _buildAnimatedLogo() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isLogoHovering = true),
      onExit: (_) {
        setState(() {
          _isLogoHovering = false;
          _logoOffset = Offset.zero; 
        });
      },
      onHover: (event) {
        final screenCenter = MediaQuery.of(context).size.width / 2;
        final moveX = (event.position.dx - screenCenter) / screenCenter * 10;
        setState(() {
          _logoOffset = Offset(moveX, 0); 
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) 
          ..rotateY(_isLogoHovering ? 0.1 : 0) 
          ..translate(_logoOffset.dx, _logoOffset.dy), 
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _isLogoHovering
              ? [
                  BoxShadow(
                    color: kPrimaryGold.withValues(alpha: 0.7),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Hero(
          tag: "lion_logo", 
          child: Image.asset(
            'assets/images/psu_lion_logo.png',
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
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
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
        boxShadow: isFocused
            ? [
                BoxShadow(
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
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.3),
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isLoginButtonHovering
              ? [
                  BoxShadow(
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
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              HapticFeedback.lightImpact();
              _handleLogin(); 
            },
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