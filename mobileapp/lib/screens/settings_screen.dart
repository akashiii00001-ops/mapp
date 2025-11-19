import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/forgot_password_screen.dart'; 
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _newEmailController = TextEditingController();
  bool isLoading = false;

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final body = {
      'student_id': userProvider.studentId,
      'current_password': _currentPassController.text,
      'new_email': _newEmailController.text.isNotEmpty ? _newEmailController.text : null,
      'new_password': _newPassController.text.isNotEmpty ? _newPassController.text : null,
    };

    try {
      final res = await http.post(Uri.parse(Config.updateSettingsUrl), body: json.encode(body), headers: {"Content-Type": "application/json"});
      if (!mounted) return;
      final result = json.decode(res.body);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? "Unknown Error"),
        backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
      ));
      
      if (result['status'] == 'success') {
        _currentPassController.clear();
        _newPassController.clear();
        _newEmailController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleLogout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SECURITY SECTION ---
              _buildSectionCard(
                title: "Security",
                icon: FontAwesomeIcons.shieldHalved,
                iconColor: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTextField("Current Password", _currentPassController, true, icon: Icons.lock_outline),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("New Password", _newPassController, true, icon: Icons.key),
                    const SizedBox(height: 16),
                    _buildTextField("Confirm New Password", TextEditingController(), true, icon: Icons.check_circle_outline),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- CONTACT SECTION ---
              _buildSectionCard(
                title: "Contact Info",
                icon: FontAwesomeIcons.envelope,
                iconColor: Colors.blue,
                child: Column(
                  children: [
                     _buildTextField("Update Email Address", _newEmailController, false, icon: Icons.alternate_email),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- ACTION BUTTONS ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bgDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading ? const CircularProgressIndicator() : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildTextField(String label, TextEditingController ctrl, bool isPass, {IconData? icon}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54) : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}