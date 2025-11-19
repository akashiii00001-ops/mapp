import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.studentId == null) return;

    try {
      final response = await http.post(
        Uri.parse(Config.getStudentProfileUrl),
        body: json.encode({'student_id': userProvider.studentId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success' && mounted) {
          setState(() {
            profileData = result['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileData == null
              ? const Center(child: Text("Could not load profile."))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Profile Picture
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profileData!['profile_photo'] != null && profileData!['profile_photo'] != ''
                              ? NetworkImage("${Config.profileImgUrl}/${profileData!['profile_photo']}")
                              : const AssetImage('assets/images/psu_lion_logo.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${profileData!['fname']} ${profileData!['lname']}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Batch ${profileData!['batch_year']}",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                          ]
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(Icons.email, "Email", profileData!['email'] ?? "N/A"),
                            const Divider(),
                            _buildDetailRow(Icons.school, "Campus", "Bayambang Campus"),
                            const Divider(),
                            _buildDetailRow(Icons.calendar_today, "Year Graduated", profileData!['batch_year'].toString()),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0033A0), size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}