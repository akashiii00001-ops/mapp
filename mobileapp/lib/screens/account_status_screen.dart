import 'package:flutter/material.dart';
import 'package:mobileapp/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

// NEW Config Import
import 'package:mobileapp/config.dart';

class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  final _studentNumberController = TextEditingController();
  bool _isLoading = false;
  String? _status;
  String? _message;
  String? _notes;

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _status = null;
      _message = null;
      _notes = null;
    });

    try {
      // [UPDATED] Use Config
      final url = Uri.parse(Config.recoveryStatusUrl);
      
      final response = await http.post(
        url,
        body: json.encode({
          'student_number': _studentNumberController.text,
        }),
      );
      final body = json.decode(response.body);

      if (body['status'] == 'found') {
        setState(() {
          _status = body['request_status'];
          _message = _getStatusMessage(body['request_status']);
          _notes = body['admin_notes'];
        });
      } else {
        setState(() {
          _status = 'not_found';
          _message = 'No active request found for that student number.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'error';
        _message = 'Could not connect to the server.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending_admin':
        return 'Your request is pending admin approval.';
      case 'approved':
        return 'Your request has been APPROVED. You can log in with your Student Number as your password.';
      case 'denied':
        return 'Your request was DENIED by the administrator.';
      default:
        return 'Unknown status.';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending_admin':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.check_circle_outline;
      case 'denied':
        return Icons.cancel_outlined;
      case 'not_found':
        return Icons.search_off_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending_admin':
        return Colors.orangeAccent;
      case 'approved':
        return Colors.greenAccent;
      case 'denied':
        return Colors.redAccent;
      case 'not_found':
        return Colors.white70;
      default:
        return kPrimaryGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      appBar: AppBar(
        title: const Text('Check Request Status'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _studentNumberController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Student Number',
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
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: kPrimaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: _isLoading ? null : _checkStatus,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kPrimaryDark))
                  : const Text('CHECK STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            if (_status != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(_status)),
                ),
                child: Column(
                  children: [
                    Icon(_getStatusIcon(_status), color: _getStatusColor(_status), size: 60),
                    const SizedBox(height: 20),
                    Text(
                      _message ?? 'An error occurred.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    if (_notes != null && _notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Admin Notes: $_notes',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}