import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/widgets/shared_widgets.dart';
import 'package:mobileapp/config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Container(
        color: const Color(0xFFF8FAFC), 
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 5)
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                            ? NetworkImage("${Config.profileImgUrl}/${user.profilePicture}")
                            : null,
                        child: (user.profilePicture == null) 
                            ? Icon(Icons.person, size: 60, color: Colors.grey.shade400) 
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 70),

              Text(
                "${user.firstName} ${user.lastName}",
                style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Batch ${user.batchYear} • ${user.program ?? 'N/A'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              
              if (user.awards != null && user.awards != "None") ...[
                const SizedBox(height: 8),
                CustomBadge(text: user.awards!.split(',')[0], type: "warning"),
              ],

              const SizedBox(height: 30),

              // INFO GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  isDark: false,
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _infoCard(FontAwesomeIcons.graduationCap, "MAJOR", user.major ?? "N/A", Colors.blue)),
                          const SizedBox(width: 15),
                          Expanded(child: _infoCard(FontAwesomeIcons.users, "PARENTS", user.parents ?? "N/A", Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _infoCard(FontAwesomeIcons.award, "AWARDS", user.awards ?? "None", Colors.orange)),
                          const SizedBox(width: 15),
                          Expanded(child: _infoCard(FontAwesomeIcons.locationDot, "ADDRESS", user.address ?? "N/A", Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _infoCard(FontAwesomeIcons.cakeCandles, "BIRTHDATE", user.birthdate ?? "N/A", Colors.pink, isFullWidth: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}