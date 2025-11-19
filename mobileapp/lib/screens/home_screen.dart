import 'package:flutter/material.dart';
import 'package:mobileapp/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Mock data for the grid
  final List<String> batchYears =
      List.generate(11, (index) => (2024 - index).toString());

  // Mock data for "Cream of the Top"
  final List<Map<String, String>> topGraduates = [
    {"name": "Juana Dela Cruz", "award": "Summa Cum Laude"},
    {"name": "Pedro Penduko", "award": "Magna Cum Laude"},
    {"name": "Maria Clara", "award": "Cum Laude"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Image.asset(
          'assets/images/psu_lion_logo.png', // Your lion logo
          height: 40,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: psuBlue),
            onPressed: () {
              // TODO: Navigate to Group Chat System
            },
          ),
        ],
      ),
      body: _buildPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: psuBlue,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Main content of the page
  Widget _buildPageContent() {
    // We can swap widgets here based on _selectedIndex, but for
    // the mock-up, we'll just show the main page.
    return ListView(
      children: [
        _buildOfficialMessageCard(),
        _buildCreamOfTheTop(),
        _buildBatchGrid(),
      ],
    );
  }

  // Module A: Official Message
  Widget _buildOfficialMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: psuBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Message from the President",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: psuBlue,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "\"Congratulations, graduates! Your journey at PSU has prepared you to be the leaders of tomorrow. Go forth and make us proud!\"",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Module B: "Cream of the Top" Feature
  Widget _buildCreamOfTheTop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Cream of the Top (Batch 2024)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: psuBlue,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: topGraduates.length,
            itemBuilder: (context, index) {
              final grad = topGraduates[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [psuGolden, psuLightYellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: psuGolden.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.star, color: psuGolden, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      grad['name']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: psuBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      grad['award']!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Module C: Batch Year Browsing (Instagram-style)
  Widget _buildBatchGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Browse by Batch",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: psuBlue,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns like Instagram
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: batchYears.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: psuBlue.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                  // Placeholder for a cover photo
                  border: Border.all(color: psuBlue.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    "Batch\n${batchYears[index]}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: psuBlue,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}