import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/employment_history_screen.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/screens/yearbook_browser.dart';
import 'package:provider/provider.dart';
import 'package:mobileapp/theme.dart'; // Ensure psuBlue/Gold are available

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _feedData;
  bool _isLoadingFeeds = true;

  @override
  void initState() {
    super.initState();
    // 1. Initialize User Data & Check Employment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.studentId != null) {
        userProvider.fetchUserProfile();
        _checkEmploymentStatus(userProvider.studentId!);
      }
    });
    // 2. Load Feeds
    _fetchFeeds();
  }

  Future<void> _checkEmploymentStatus(int studentId) async {
    try {
      // Uses the corrected variable name from Config
      final response = await http.get(
        Uri.parse("${Config.checkEmploymentStatusUrl}?student_id=$studentId"),
      );
      final data = json.decode(response.body);
      
      if (data['status'] == 'not_found') {
        if (mounted) {
          // Show Mandatory Form
          showDialog(
            context: context,
            barrierDismissible: false, // User MUST fill this out
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.all(10),
              child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: const SizedBox(
                   height: 600,
                   child: EmploymentHistoryScreen(isMandatory: true),
                 ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Employment check failed: $e");
    }
  }

  Future<void> _fetchFeeds() async {
    try {
      // Uses the corrected variable name from Config
      final response = await http.get(Uri.parse(Config.getFeedsUrl));
      if (response.statusCode == 200) {
        setState(() {
          _feedData = json.decode(response.body);
          _isLoadingFeeds = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingFeeds = false);
    }
  }

  void _logout() {
    context.read<UserProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UpgradedLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PSU Yearbook'),
        centerTitle: true,
        actions: [
          // Profile Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 30),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'employment') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen()));
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
               const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, color: Colors.grey), SizedBox(width: 10), Text('Settings')])),
               const PopupMenuItem(value: 'employment', child: Row(children: [Icon(Icons.work, color: Colors.grey), SizedBox(width: 10), Text('Employment History')])),
               const PopupMenuDivider(),
               const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 10), Text('Logout')])),
            ],
          ),
        ],
      ),
      
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: psuBlue),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.school, size: 50, color: Colors.white),
                     SizedBox(height: 10),
                     Text("Theme Settings", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text("Light Mode"),
              onTap: () { themeProv.setMode(AppThemeMode.light); Navigator.pop(context); },
              selected: themeProv.currentMode == AppThemeMode.light,
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              onTap: () { themeProv.setMode(AppThemeMode.dark); Navigator.pop(context); },
              selected: themeProv.currentMode == AppThemeMode.dark,
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text("PSU Theme"),
              onTap: () { themeProv.setMode(AppThemeMode.psu); Navigator.pop(context); },
              selected: themeProv.currentMode == AppThemeMode.psu,
            ),
          ],
        ),
      ),

      body: _isLoadingFeeds
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFeeds,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Announcements"),
                    _buildHorizontalList(_feedData?['announcements'], 'message', Colors.orange.shade50),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle("Upcoming Events"),
                    _buildHorizontalList(_feedData?['events'], 'description', Colors.blue.shade50),
                    
                    const SizedBox(height: 20),
                    _buildSectionTitle("Job Hirings"),
                    _buildHorizontalList(_feedData?['jobs'], 'description', Colors.green.shade50),
                    
                    const SizedBox(height: 80), // Spacing for FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const YearbookBrowser()));
        },
        label: const Text("Browse Yearbook"),
        icon: const Icon(Icons.auto_stories),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHorizontalList(List<dynamic>? items, String subtitleKey, Color bgColor) {
    if (items == null || items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("No updates available."),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'No Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text(
                  item['date'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Divider(),
                Expanded(
                  child: Text(
                    item[subtitleKey] ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}