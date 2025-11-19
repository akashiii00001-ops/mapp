import 'dart:convert';
import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/services/gemini_service.dart';
import 'package:mobileapp/widgets/shared_widgets.dart';

// Screens
import 'package:mobileapp/screens/profile_screen.dart';
import 'package:mobileapp/screens/employment_history_screen.dart';
import 'package:mobileapp/screens/settings_screen.dart';
import 'package:mobileapp/screens/about_screen.dart';
import 'package:mobileapp/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> feedData = {'announcements': [], 'events': [], 'jobs': []};
  bool isLoading = true;
  
  // Gemini State
  bool isGeminiLoading = false;
  String geminiTitle = "";
  String? geminiResult;
  String? geminiError;

  @override
  void initState() {
    super.initState();
    _fetchFeedData();
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _callGemini(String prompt, String title) async {
    setState(() {
      geminiTitle = title;
      isGeminiLoading = true;
      geminiResult = null;
      geminiError = null;
    });
    _showGeminiModal();

    final result = await GeminiService.generateContent(prompt);
    
    if (!mounted) return;

    setState(() {
      if (result.startsWith("Error")) {
        geminiError = result;
      } else {
        geminiResult = result;
      }
      isGeminiLoading = false;
    });
  }

  void _showGeminiModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
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
                        const Icon(FontAwesomeIcons.wandMagicSparkles, color: Color(0xFFFDE047), size: 20)
                            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms), // Fixed animation
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
                          ? Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(color: Color(0xFFA855F7)),
                                  const SizedBox(height: 16),
                                  Text("Consulting Gemini...", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                                ],
                              ),
                            )
                          : Text(
                              geminiResult ?? geminiError ?? "",
                              style: const TextStyle(color: Colors.white, height: 1.6),
                            ),
                    ),
                  ),
                  if (!isGeminiLoading && geminiResult != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))
                      ),
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: geminiResult!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                        label: const Text("Copy Text", style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                      ),
                    )
                ],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkContent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildCustomAppBar(user, theme, isDark),
      body: GradientBackground(
        themeMode: theme.currentMode,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(top: 110, bottom: 40),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCarouselSection("Announcements", FontAwesomeIcons.bullhorn, feedData['announcements'], 'announcement', isDark),
                  _buildCarouselSection("Upcoming Events", FontAwesomeIcons.calendarDays, feedData['events'], 'event', isDark),
                  _buildCarouselSection("Featured Opportunities", FontAwesomeIcons.briefcase, feedData['jobs'], 'job', isDark),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(UserProvider user, ThemeProvider theme, bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40, width: 40,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.asset('assets/images/psu_lion_logo.png')),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("PSU Yearbook", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Welcome back, ${user.firstName ?? 'Alumni'}", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(theme.currentMode == 'light' ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.white : Colors.black54),
                        onPressed: () => theme.cycleTheme(),
                      ),
                      IconButton(
                        icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black54),
                        onPressed: () => _showMenuModal(context, user, theme),
                      ),
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

  Widget _buildCarouselSection(String title, IconData icon, List<dynamic>? items, String type, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 340,
          child: (items == null || items.isEmpty)
            ? Center(child: Text("No updates.", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildCardContent(item, type, index, isDark);
                },
              ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCardContent(Map<String, dynamic> item, String type, int index, bool isDark) {
    String title = item['title'] ?? item['job_title'] ?? "No Title";
    String desc = item['message'] ?? item['description'] ?? item['company_name'] ?? "";
    String date = item['created_at']?.toString().split(' ')[0] ?? "";
    String? photo = item['photo_path'];
    String imgUrl = "";
    
    if (photo != null) {
      if (photo.contains('uploads/')) {
         String clean = photo.startsWith('/') ? photo.substring(1) : photo;
         imgUrl = "${Config.projectRootUrl}/$clean";
      } else {
        String folder = (type == 'announcement') ? Config.announcementImgUrl : (type == 'event') ? Config.eventImgUrl : Config.jobImgUrl;
        imgUrl = "$folder/$photo";
      }
    }

    return Card3D(
      isDark: isDark,
      imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
      delay: (index * 100).toDouble(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomBadge(
                text: type == 'job' ? (item['type'] ?? 'JOB') : type,
                type: type == 'announcement' ? 'primary' : (type == 'job' ? 'success' : 'warning'),
              ),
              Text(date, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
          const Spacer(), // This now works because Card3D forces a height
          if (type == 'event')
            _actionBtn(FontAwesomeIcons.message, "Icebreakers", Colors.purple, () {
              _callGemini(
                "I am an alumni attending '$title'. Generate 3 witty icebreakers.",
                "Icebreakers for $title"
              );
            }),
          if (type == 'job')
            _actionBtn(FontAwesomeIcons.filePen, "Draft Apply", Colors.blue, () {
              _callGemini(
                "Write a cover letter opening for position '$title' at '${item['company_name']}'.",
                "Draft for ${item['company_name']}"
              );
            }),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showMenuModal(BuildContext context, UserProvider user, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.isDarkContent ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             ListTile(
               leading: const Icon(Icons.person), 
               title: const Text("My Profile"),
               onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }
             ),
             ListTile(
               leading: const Icon(Icons.work), 
               title: const Text("Employment History"),
               onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const EmploymentHistoryScreen())); }
             ),
             ListTile(
               leading: const Icon(Icons.settings), 
               title: const Text("Settings"),
               onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }
             ),
             ListTile(
               leading: const Icon(Icons.info), 
               title: const Text("About"),
               onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())); }
             ),
             const Divider(),
             ListTile(
               leading: const Icon(Icons.logout, color: Colors.red), 
               title: const Text("Log Out", style: TextStyle(color: Colors.red)),
               onTap: () { 
                 Navigator.pop(ctx);
                 user.logout();
                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
               }
             ),
          ],
        ),
      ),
    );
  }
}