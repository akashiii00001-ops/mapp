import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark Theme Constants
    const Color bgDark = Color(0xFF0F172A);
    
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : profileData == null
              ? const Center(child: Text("Could not load profile.", style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // --- HEADER SECTION ---
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomLeft,
                        children: [
                          // Gradient Cover
                          Container(
                            height: 220,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)], // Indigo to Purple
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                            ),
                          ),
                          // Profile Picture
                          Positioned(
                            bottom: -50,
                            left: 30,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: bgDark,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade800,
                                backgroundImage: profileData!['profile_photo'] != null && profileData!['profile_photo'] != ''
                                    ? NetworkImage("${Config.profileImgUrl}/${profileData!['profile_photo']}")
                                    : const AssetImage('assets/images/psu_lion_logo.png') as ImageProvider,
                              ),
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // --- NAME & DETAILS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${profileData!['fname']} ${profileData!['lname']}",
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    Text(
                                      "Batch ${profileData!['batch_year']} • ${profileData!['program'] ?? 'Alumni'}",
                                      style: const TextStyle(fontSize: 14, color: Colors.white54),
                                    ),
                                  ],
                                ),
                                if (profileData!['honors'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: const Text("HONORS", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),

                            const SizedBox(height: 30),

                            // --- GLASS CARD: STATS ---
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(FontAwesomeIcons.envelope, "Email", profileData!['email'] ?? "N/A"),
                                      const Divider(color: Colors.white10),
                                      _buildDetailRow(FontAwesomeIcons.buildingColumns, "Campus", "Bayambang Campus"),
                                      const Divider(color: Colors.white10),
                                      _buildDetailRow(FontAwesomeIcons.userGraduate, "Major", profileData!['major'] ?? "N/A"),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                            
                            const SizedBox(height: 20),

                            // --- SECONDARY DETAILS GRID ---
                            Row(
                              children: [
                                Expanded(child: _buildGridCard(FontAwesomeIcons.cakeCandles, "Birthday", profileData!['birthdate'] ?? "N/A", Colors.pinkAccent)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildGridCard(FontAwesomeIcons.locationDot, "Address", profileData!['address'] ?? "N/A", Colors.orangeAccent)),
                              ],
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.blueAccent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}