import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/screens/login_screen.dart';
import 'package:mobileapp/screens/profile_screen.dart';
import 'package:mobileapp/screens/employment_history_screen.dart';
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/screens/about_screen.dart';         
import 'package:mobileapp/screens/notifications_screen.dart'; 

// TODO: Replace with your actual Gemini API Key
const String _kGeminiApiKey = "YOUR_GEMINI_API_KEY_HERE";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> feedData = {'announcements': [], 'events': [], 'jobs': []};
  bool isLoading = true;
  bool isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  // Gemini State
  bool isGeminiLoading = false;
  String? geminiResult;
  String? geminiError;
  String geminiTitle = "";

  @override
  void initState() {
    super.initState();
    _fetchFeedData();
    
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset > 20 && !isScrolled) {
        setState(() => isScrolled = true);
      } else if (_scrollController.offset <= 20 && isScrolled) {
        setState(() => isScrolled = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false);
      user.refreshProfile();
      _checkEmploymentStatus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.studentId == null) return;
    try {
      final response = await http.get(Uri.parse("${Config.checkEmploymentStatusUrl}?student_id=${user.studentId}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'not_found' && mounted) {
          _showForceUpdateDialog();
        }
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Action Required", style: TextStyle(color: Colors.white)),
        content: const Text("Please update your employment history to proceed.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen(isForced: true)));
            },
            child: const Text("Update Now", style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      ),
    );
  }

  // --- GEMINI API CALL ---
  Future<void> _callGemini(String prompt, String title) async {
    setState(() {
      isGeminiLoading = true;
      geminiResult = null;
      geminiError = null;
      geminiTitle = title;
    });

    _showGeminiModal();

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_kGeminiApiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "No response generated.";
        
        if (mounted) {
          setState(() {
            geminiResult = text;
            isGeminiLoading = false;
          });
          Navigator.pop(context); 
          _showGeminiModal(); 
        }
      } else {
        throw Exception("Status ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          geminiError = "Failed to connect to Gemini. Please try again.";
          isGeminiLoading = false;
        });
        Navigator.pop(context);
        _showGeminiModal();
      }
    }
  }

  void _showGeminiModal() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95), 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.wandMagicSparkles, color: Color(0xFFFDE047), size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(geminiTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: isGeminiLoading
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFFA855F7)),
                                  SizedBox(height: 16),
                                  Text("Consulting Gemini...", style: TextStyle(color: Colors.white54)),
                                ],
                              )
                            : Text(
                                geminiResult ?? geminiError ?? "",
                                style: const TextStyle(color: Colors.white, height: 1.5),
                              ),
                      ),
                    ),
                    if (!isGeminiLoading && geminiResult != null)
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             TextButton.icon(
                               onPressed: () {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
                                 Navigator.pop(context);
                               },
                               icon: const Icon(Icons.copy, size: 16),
                               label: const Text("Copy"),
                               style: TextButton.styleFrom(foregroundColor: Colors.white54),
                             )
                           ],
                         ),
                       )
                  ],
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    const Color bgDark = Color(0xFF0F172A); 

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(user, bgDark),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: _fetchFeedData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 120, bottom: 40),
                child: Column(
                  children: [
                    _buildSection("Announcements", FontAwesomeIcons.bullhorn, 
                      _buildCarousel(feedData['announcements'], 'announcement', 300, 220)),
                    const SizedBox(height: 30),
                    _buildSection("Upcoming Events", FontAwesomeIcons.calendarDays, 
                      _buildCarousel(feedData['events'], 'event', 260, 280, isEvent: true)),
                    const SizedBox(height: 30),
                    _buildSection("Featured Opportunities", FontAwesomeIcons.wandMagicSparkles, 
                      _buildCarousel(feedData['jobs'], 'job', 280, 260, isJob: true)),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(UserProvider user, Color bgDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isScrolled ? bgDark.withValues(alpha: 0.8) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 45, width: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 10)]
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset('assets/images/psu_lion_logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("PSU Yearbook", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Welcome back, ${user.firstName ?? 'Alumni'}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.bell, color: Colors.white, size: 20),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      ),
                      _buildMenuButton(user),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(UserProvider user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                ? NetworkImage("${Config.profileImgUrl}/${user.profilePicture}") 
                : null,
              backgroundColor: Colors.blue,
              child: (user.profilePicture == null || user.profilePicture!.isEmpty) ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.menu, color: Colors.white, size: 18),
          ],
        ),
      ),
      onSelected: (val) {
          if (val == 'logout') _handleLogout();
          else if (val == 'profile') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          else if (val == 'employment') Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen()));
          else if (val == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          else if (val == 'about') Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          else if (val == 'notifications') Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      },
      itemBuilder: (ctx) => [
          _buildPopupItem('profile', FontAwesomeIcons.user, "My Profile"),
          _buildPopupItem('notifications', FontAwesomeIcons.bell, "Notifications"),
          _buildPopupItem('employment', FontAwesomeIcons.briefcase, "Employment"),
          _buildPopupItem('settings', FontAwesomeIcons.gear, "Settings"),
          _buildPopupItem('about', FontAwesomeIcons.circleInfo, "About"),
          const PopupMenuDivider(),
          _buildPopupItem('logout', FontAwesomeIcons.rightFromBracket, "Log Out", isDestructive: true),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDestructive ? Colors.redAccent : Colors.grey),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildCarousel(List<dynamic>? items, String type, double width, double height, {bool isEvent = false, bool isJob = false}) {
    if (items == null || items.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: const Text("No updates available.", style: TextStyle(color: Colors.white38)),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _build3DCard(items[index], type, width, index, isEvent, isJob);
        },
      ),
    );
  }

  Widget _build3DCard(Map<String, dynamic> item, String type, double width, int index, bool isEvent, bool isJob) {
    String title = item['title'] ?? item['job_title'] ?? "No Title";
    String subtitle = item['message'] ?? item['company_name'] ?? item['description'] ?? "";
    String? photoPath = item['photo_path'];
    String date = item['created_at'] ?? "Recently";
    
    String imageUrl = "";
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.contains('uploads/')) {
         String cleanPath = photoPath.startsWith('/') ? photoPath.substring(1) : photoPath;
         imageUrl = "${Config.projectRootUrl}/$cleanPath"; 
      } else {
        if (type == 'announcement') imageUrl = "${Config.announcementImgUrl}/$photoPath";
        else if (type == 'event') imageUrl = "${Config.eventImgUrl}/$photoPath";
        else if (type == 'job') imageUrl = "${Config.jobImgUrl}/$photoPath";
      }
    }

    Color tagColor = Colors.blue;
    String tagText = type.toUpperCase();
    if (type == 'job') { tagColor = Colors.green; tagText = item['type'] ?? "FULL-TIME"; }
    if (type == 'event') { tagColor = Colors.purple; }

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // 1. IMAGE AREA (Fixed flex)
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                          ),
                        )
                      else
                        Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Center(child: Icon(isJob ? FontAwesomeIcons.briefcase : FontAwesomeIcons.image, color: Colors.white24, size: 40)),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          )
                        ),
                      ),
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: tagColor.withValues(alpha: 0.5))),
                          child: Text(tagText, style: TextStyle(color: tagColor.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. CONTENT AREA (Fixed flex but scrolling content)
                Expanded(
                  flex: (isEvent || isJob) ? 3 : 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date.split(' ')[0], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        const SizedBox(height: 4),
                        // Title - limited lines
                        Text(
                          title, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        const SizedBox(height: 4),
                        
                        // Description - flexible
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              subtitle, 
                              style: const TextStyle(color: Colors.white70, fontSize: 12)
                            ),
                          ),
                        ),
                        
                        // Action Buttons
                        if (isEvent) ...[
                          const SizedBox(height: 12),
                          _buildGeminiActionBtn(
                            icon: FontAwesomeIcons.solidMessage,
                            text: "Icebreakers",
                            color: Colors.purpleAccent,
                            onTap: () => _callGemini(
                              "I am an alumni attending a university event titled '$title'. Generate 3 witty, professional icebreaker questions.",
                              "Icebreakers for '$title'"
                            ),
                          ),
                        ] else if (isJob) ...[
                          const SizedBox(height: 12),
                          _buildGeminiActionBtn(
                            icon: FontAwesomeIcons.filePen,
                            text: "Draft Apply",
                            color: Colors.blueAccent,
                            onTap: () => _callGemini(
                              "Write a concise, enthusiastic cover letter opening paragraph for a Computer Science alumni applying for '$title' at '${item['company_name'] ?? 'this company'}'.",
                              "Draft for '${item['company_name'] ?? 'Job'}'"
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        _callGemini("Tell me a fun fact about Pangasinan State University.", "PSU Assistant");
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 60, width: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.pink, Colors.pinkAccent]),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: const Icon(FontAwesomeIcons.robot, color: Colors.white),
      ),
    ).animate().scale(delay: 1000.ms, duration: 500.ms, curve: Curves.elasticOut);
  }

  void _handleLogout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }
}