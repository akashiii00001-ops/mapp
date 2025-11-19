import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:mobileapp/config.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/employment_history_screen.dart'; // Ensure this matches the filename below
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/yearbook_browser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _feedData;
  bool _isLoading = true;
  bool _hasNewNotifications = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.studentId != null) {
        _checkEmployment(user.studentId!);
        _fetchFeeds(user.studentId!);
      }
    });
  }

  Future<void> _checkEmployment(int studentId) async {
    try {
      final response = await http.get(Uri.parse("${Config.checkEmploymentStatusUrl}?student_id=$studentId"));
      final data = json.decode(response.body);

      if (data['status'] == 'not_found' && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User MUST fill this
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const SizedBox(
              height: 650, 
              child: EmploymentHistoryScreen(isMandatory: true),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Employment Check Error: $e");
    }
  }

  Future<void> _fetchFeeds(int studentId) async {
    try {
      final response = await http.get(Uri.parse("${Config.getFeedsUrl}?student_id=$studentId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _feedData = data;
          _hasNewNotifications = data['has_notification'] ?? false;
          _isLoading = false;
        });

        if (_hasNewNotifications) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have new announcements!"),
              backgroundColor: kPrimaryGold,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PSU Yearbook'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kPrimaryGold,
          indicatorWeight: 3,
          labelColor: kPrimaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "News", icon: Icon(Icons.campaign_outlined)),
            Tab(text: "Events", icon: Icon(Icons.calendar_month_outlined)),
            Tab(text: "Careers", icon: Icon(Icons.work_outline)),
          ],
        ),
        actions: [
          Stack(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle, size: 28),
                offset: const Offset(0, 50),
                onSelected: (value) {
                  if (value == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  if (value == 'history') Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen(isMandatory: false)));
                  if (value == 'logout') {
                    context.read<UserProvider>().logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UpgradedLoginScreen()), (r) => false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'history', child: ListTile(leading: Icon(Icons.history_edu, color: kPrimaryBlue), title: Text("Employment History"))),
                  const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings, color: kPrimaryBlue), title: Text("Settings"))),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Logout", style: TextStyle(color: Colors.red)))),
                ],
              ),
              if (_hasNewNotifications)
                Positioned(
                  right: 8, top: 8,
                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                ),
            ],
          )
        ],
      ),
      
      drawer: _buildThemeDrawer(context),
      
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedList(_feedData?['announcements'], 'message', Icons.campaign, Colors.orange.shade50),
                _buildFeedList(_feedData?['events'], 'description', Icons.event, Colors.blue.shade50),
                _buildFeedList(_feedData?['jobs'], 'description', Icons.business_center, Colors.green.shade50),
              ],
            ),
            
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const YearbookBrowser()));
        },
        label: const Text("My Yearbook"),
        icon: const Icon(FontAwesomeIcons.bookOpen),
        backgroundColor: kPrimaryGold,
        foregroundColor: kPrimaryDark,
      ),
    );
  }

  Widget _buildFeedList(List<dynamic>? items, String subKey, IconData icon, Color bgColor) {
    if (items == null || items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        const Text("No updates available", style: TextStyle(color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(backgroundColor: bgColor, child: Icon(icon, color: Colors.black54)),
            title: Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(item[subKey] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if(item['location'] != null) ...[
                       const SizedBox(width: 10),
                       const Icon(Icons.location_on, size: 14, color: Colors.grey),
                       const SizedBox(width: 4),
                       Text(item['location'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeDrawer(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimaryDark, kPrimaryBlue])),
            currentAccountPicture: const CircleAvatar(backgroundImage: AssetImage('assets/images/psu_lion_logo.png')),
            accountName: const Text("Theme Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text("Select your preferred look", style: TextStyle(color: Colors.white.withOpacity(0.8))),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode), title: const Text("Light Mode"),
            trailing: themeProv.currentMode == AppThemeMode.light ? const Icon(Icons.check, color: kPrimaryGold) : null,
            onTap: () => themeProv.setMode(AppThemeMode.light),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode), title: const Text("Dark Mode"),
            trailing: themeProv.currentMode == AppThemeMode.dark ? const Icon(Icons.check, color: kPrimaryGold) : null,
            onTap: () => themeProv.setMode(AppThemeMode.dark),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber), title: const Text("PSU Theme"),
            trailing: themeProv.currentMode == AppThemeMode.psu ? const Icon(Icons.check, color: kPrimaryGold) : null,
            onTap: () => themeProv.setMode(AppThemeMode.psu),
          ),
        ],
      ),
    );
  }
}