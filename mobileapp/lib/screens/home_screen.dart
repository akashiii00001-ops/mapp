import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/screens/employment_history_screen.dart';
import 'package:mobileapp/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> feedData = {'announcements': [], 'events': [], 'jobs': []};
  bool isLoading = true;
  bool hasCheckedEmployment = false;

  @override
  void initState() {
    super.initState();
    _fetchFeedData();
    
    // Check employment status once the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If name is missing, try to fetch it
      final user = Provider.of<UserProvider>(context, listen: false);
      if (user.fullName == null) {
        user.refreshProfile();
      }

      if (!hasCheckedEmployment) {
        _checkEmploymentStatus();
      }
    });
  }

  Future<void> _fetchFeedData() async {
    try {
      final response = await http.get(Uri.parse(Config.getHomeDataUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            feedData = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching feed: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkEmploymentStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentId = userProvider.studentId;

    if (studentId == null) return;

    try {
      final response = await http.get(
        Uri.parse("${Config.checkEmploymentStatusUrl}?student_id=$studentId"),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'not_found') {
          if (!mounted) return;
          // Show Dialog forcing them to update
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Action Required"),
              content: const Text("Please update your employment history to proceed."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen(isForced: true))
                    );
                  },
                  child: const Text("Update Now"),
                )
              ],
            ),
          );
        }
      }
      setState(() {
        hasCheckedEmployment = true;
      });
    } catch (e) {
      debugPrint("Error checking status: $e");
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
    final userProvider = Provider.of<UserProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 15,
        title: Row(
          children: [
            // Make sure you have this asset
            Image.asset('assets/images/psu_lion_logo.png', height: 35), 
            const SizedBox(width: 10),
            const Text(
              "PSU Yearbook",
              style: TextStyle(color: Color(0xFF0033A0), fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            icon: const Icon(Icons.account_circle, color: Colors.black87, size: 32),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  break;
                case 'employment':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hi, ${userProvider.fullName ?? 'Student'}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person, color: Colors.grey), SizedBox(width: 8), Text("My Profile")])),
                const PopupMenuItem(value: 'employment', child: Row(children: [Icon(Icons.work, color: Colors.grey), SizedBox(width: 8), Text("Employment History")])),
                const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 8), Text("Settings")])),
                const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text("Logout")])),
              ];
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFeedData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0033A0), Color(0xFF001F5F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 5),
                          Text(
                            userProvider.fullName ?? "Alumni", 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 5),
                          Text("Batch ${userProvider.batchYear ?? '...'}", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Announcements
                    _buildSectionHeader("Announcements", Icons.campaign, Colors.orange),
                    _buildCarousel(feedData['announcements'], "announcements"),

                    // 2. Events
                    _buildSectionHeader("Upcoming Events", Icons.event, Colors.blue),
                    _buildCarousel(feedData['events'], "events"),

                    // 3. Jobs
                    _buildSectionHeader("Job Hiring", Icons.work, Colors.green),
                    _buildCarousel(feedData['jobs'], "jobs"),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<dynamic>? items, String type) {
    if (items == null || items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: const Center(child: Text("No updates currently available.", style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildCard(items[index], type);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, String type) {
    String title = item['title'] ?? item['job_title'] ?? "No Title";
    String subtitle = item['message'] ?? item['description'] ?? item['company_name'] ?? "";
    String? photoPath = item['photo_path'];
    
    // Correct URL construction based on Config
    String imageUrl = "";
    if (photoPath != null && photoPath.isNotEmpty) {
      if (type == 'announcements') imageUrl = "${Config.announcementImgUrl}/$photoPath";
      else if (type == 'events') imageUrl = "${Config.eventImgUrl}/$photoPath";
      else if (type == 'jobs') imageUrl = "${Config.jobImgUrl}/$photoPath";
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 130,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                      },
                    )
                  : Center(child: Icon(type == 'jobs' ? Icons.work : Icons.event, size: 40, color: Colors.grey.shade300)),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}