import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/config.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newValueCtrl = TextEditingController();

  void _showUpdateDialog(String type) {
    _currentPassCtrl.clear();
    _newValueCtrl.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change $type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please verify your identity to continue."),
            const SizedBox(height: 10),
            TextField(
              controller: _currentPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _newValueCtrl,
              obscureText: type == "Password",
              decoration: InputDecoration(labelText: "New $type", border: const OutlineInputBorder(), prefixIcon: Icon(type == "Password" ? Icons.key : Icons.email)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGold),
            onPressed: () {
              Navigator.pop(context);
              _submitUpdate(type);
            },
            child: const Text("Update", style: TextStyle(color: kPrimaryDark)),
          )
        ],
      ),
    );
  }

  Future<void> _submitUpdate(String type) async {
    showLoadingDialog(context, "Updating...");
    final user = context.read<UserProvider>();

    try {
      final response = await http.post(
        Uri.parse(Config.updateSettingsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': user.studentId,
          'type': type.toLowerCase(),
          'value': _newValueCtrl.text,
          'current_password': _currentPassCtrl.text,
        }),
      );

      Navigator.pop(context); // Close loader
      final data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']),
          backgroundColor: data['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Account Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.password, color: kPrimaryGold),
              title: const Text("Change Password"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showUpdateDialog("Password"),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.email, color: kPrimaryGold),
              title: const Text("Change Email"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showUpdateDialog("Email"),
            ),
          ),
        ],
      ),
    );
  }
}