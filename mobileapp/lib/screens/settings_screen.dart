import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/login_screen.dart'; 
import 'package:provider/provider.dart';

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
    final studentId = userProvider.studentId;

    final body = {
      'student_id': studentId,
      'current_password': _currentPassController.text,
      'new_email': _newEmailController.text.isNotEmpty ? _newEmailController.text : null,
      'new_password': _newPassController.text.isNotEmpty ? _newPassController.text : null,
    };

    try {
      final res = await http.post(
        Uri.parse(Config.updateSettingsUrl),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"},
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleLogout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Update Profile Credentials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: "New Email (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const Divider(height: 40),
              const Text("Confirm Changes", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password (Required)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) => v!.isEmpty ? "Current password is required" : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}