import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/widgets/employment_modal.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> feedData = {'announcements': [], 'events': [], 'jobs': []};
  bool isLoading = true;
  // Default to true to ensure we check; logic will handle showing only if needed
  bool hasCheckedEmployment = false; 

  @override
  void initState() {
    super.initState();
    _fetchFeedData();
    
    // Check employment status immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasCheckedEmployment) {
        _checkEmploymentStatus();
      }
    });
  }

  Future<void> _fetchFeedData() async {
    try {
      final response = await http.get(Uri.parse("${Config.apiUrl}/get_home_data.php"));
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
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => EmploymentModal(studentId: studentId.toString()),
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

  void _handleLogout(BuildContext context) {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Provider.of<UserProvider>(context, listen: false).logout();
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isPsuTheme = themeProvider.currentThemeType == 'psu';

    return Scaffold(
      backgroundColor: isPsuTheme ? const Color(0xFFFFFDD0) : const Color(0xFFF0F2F5), // FB-like gray background
      appBar: AppBar(
        backgroundColor: isPsuTheme ? const Color(0xFF0033A0) : Colors.white,
        elevation: isPsuTheme ? 4 : 1,
        title: Text(
          "PSU Yearbook", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isPsuTheme ? Colors.white : const Color(0xFF1877F2), // FB Blue
            fontSize: 24
          )
        ),
        actions: [
          // Light Bulb Icon for Theme Toggle
          IconButton(
            icon: Icon(
              isPsuTheme ? Icons.lightbulb : Icons.lightbulb_outline, 
              color: isPsuTheme ? Colors.yellowAccent : Colors.black87
            ),
            tooltip: "Switch Theme",
            onPressed: () {
              // Toggle between 'psu' and 'light' (FB style)
              if (isPsuTheme) {
                themeProvider.setTheme('light');
              } else {
                themeProvider.setTheme('psu');
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle, size: 30, color: isPsuTheme ? Colors.white : Colors.black87),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'settings') {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                 PopupMenuItem(
                  value: 'header',
                  enabled: false,
                  child: Text("Hi, ${userProvider.fullName ?? 'Student'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [Icon(Icons.work_history, color: Colors.grey), SizedBox(width: 8), Text("Employment History")],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 8), Text("Settings")],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text("Logout")],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFeedData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Announcements Carousel
                    _buildSectionTitle("Announcements", Icons.campaign, Colors.orange),
                    _buildCarousel(feedData['announcements'], "announcements"),

                    // 2. Events Carousel
                    _buildSectionTitle("Upcoming Events", Icons.event, Colors.blue),
                    _buildCarousel(feedData['events'], "events"),

                    // 3. Job Hiring Carousel
                    _buildSectionTitle("Job Hiring", Icons.work, Colors.green),
                    _buildCarousel(feedData['jobs'], "jobs"),
                    
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yearbook Feature Coming Soon!")));
        },
        backgroundColor: isPsuTheme ? const Color(0xFFFFD700) : const Color(0xFF1877F2),
        icon: Icon(Icons.auto_stories, color: isPsuTheme ? Colors.black : Colors.white),
        label: Text("My Yearbook", style: TextStyle(color: isPsuTheme ? Colors.black : Colors.white)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<dynamic>? items, String type) {
    if (items == null || items.isEmpty) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Text("No updates available.", style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 260, // Height for the carousel
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildCarouselCard(item, type);
        },
      ),
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> item, String type) {
    String title = item['title'] ?? item['job_title'] ?? "No Title";
    String subtitle = item['message'] ?? item['description'] ?? item['company_name'] ?? "";
    String? photoPath = item['photo_path'];
    
    // Construct Image URL
    String imageUrl = "";
    if (photoPath != null && photoPath.isNotEmpty) {
      imageUrl = "${Config.apiUrl}/$photoPath"; 
    }

    return Container(
      width: 280, // Width of each card
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            // Fix for deprecated withOpacity
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                      },
                    )
                  : Center(
                      child: Icon(
                        type == 'jobs' ? Icons.work : (type == 'events' ? Icons.event : Icons.campaign),
                        size: 40, 
                        color: Colors.grey.shade400
                      )
                    ),
            ),
          ),
          // Text Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  // "See More" fake button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "See Details", 
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}