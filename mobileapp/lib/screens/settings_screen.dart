import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/widgets/shared_widgets.dart';
import 'package:mobileapp/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // --- 1. CHANGE PASSWORD ---
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password', filled: true, fillColor: Colors.black12, labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', filled: true, fillColor: Colors.black12, labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performSecurityAction('change_password', {'old_password': oldPassCtrl.text, 'new_password': newPassCtrl.text});
            },
            child: const Text("Update", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // --- 2. UPDATE EMAIL FLOW (SEQUENTIAL) ---
  Future<void> _startEmailUpdateFlow() async {
    // Step 1: Confirm and Send OTP to OLD Email
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Update Email Address", style: TextStyle(color: Colors.white)),
        content: const Text("We will send an OTP to your CURRENT email to verify it's you.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Send OTP", style: TextStyle(color: Colors.blue))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    bool otpSent = await _performSecurityAction('send_otp_current', {});
    if (!otpSent || !mounted) return;

    // Step 2: Verify OTP
    String? otpCode = await _showInput(context, "Enter Verification Code", "6-Digit Code", isNumber: true);
    if (otpCode == null || otpCode.isEmpty || !mounted) return;

    bool verified = await _performSecurityAction('verify_otp', {'code': otpCode});
    if (!verified || !mounted) return;

    // Step 3: Enter NEW Email
    String? newEmail = await _showInput(context, "Enter New Email", "new@email.com");
    if (newEmail == null || newEmail.isEmpty || !mounted) return;

    // Step 4: Send OTP to NEW Email (Optional verification step, or direct update)
    // For simplicity per your request: Direct update after verifying old email logic
    // OR strictly: Send OTP to new email. Let's do direct update as per "where do i change the mail" request.
    await _performSecurityAction('update_email', {'code': otpCode, 'new_email': newEmail}); // Re-sending OTP code for backend validation context
  }

  // --- 3. FORGOT PASSWORD ---
  Future<void> _forgotPasswordFlow() async {
     bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
        content: const Text("We will send a temporary password or reset link to your registered email.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Send Email", style: TextStyle(color: Colors.orange))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _performSecurityAction('forgot_password', {});
    }
  }

  // Helper for inputs
  Future<String?> _showInput(BuildContext context, String title, String hint, {bool isNumber = false}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl, 
          keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
          decoration: InputDecoration(labelText: hint, filled: true, fillColor: Colors.black12, labelStyle: const TextStyle(color: Colors.white70)), 
          style: const TextStyle(color: Colors.white)
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Next", style: TextStyle(color: Colors.blue))),
        ],
      ),
    );
  }

  Future<bool> _performSecurityAction(String action, Map<String, dynamic> extras) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final url = Uri.parse(Config.settingsActionUrl); 

    try {
      final body = {'action': action, 'student_id': user.studentId, ...extras};
      final response = await http.post(url, body: json.encode(body));
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Success')));
        return true;
      } else {
        if (mounted) _showError(data['message']);
        return false;
      }
    } catch (e) {
      if (mounted) _showError("Connection Error: $e");
      return false;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkContent;

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        themeMode: theme.currentMode,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
          child: GlassContainer(
            isDark: isDark,
            child: Column(
              children: [
                _sectionHeader("Security", Icons.security, Colors.orange, isDark),
                const SizedBox(height: 16),
                
                _menuItem("Change Password", Icons.lock, isDark, onTap: () => _showChangePasswordDialog(context)),
                const Divider(),
                _menuItem("Update Email", Icons.email, isDark, onTap: _startEmailUpdateFlow),
                const Divider(),
                _menuItem("Forgot Password", Icons.help_outline, isDark, onTap: _forgotPasswordFlow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon, bool isDark, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}