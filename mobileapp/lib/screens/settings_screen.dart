import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userId = context.read<UserProvider>().studentId;

    try {
      final response = await http.post(
        Uri.parse(Config.updateSettingsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': userId,
          'current_password': _currentPassController.text,
          'new_email': _newEmailController.text,
          'new_password': _newPassController.text,
        }),
      );

      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Unknown response')),
      );

      if (data['status'] == 'success') {
        _currentPassController.clear();
        _newPassController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to server')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Security Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _currentPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password (Required)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) => v!.isEmpty ? 'Enter current password' : null,
              ),
              const Divider(height: 40),
              const Text("Update Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'New Email Address (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateSettings,
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}