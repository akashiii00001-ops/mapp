import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/providers/theme_provider.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/widgets/shared_widgets.dart';
import 'package:mobileapp/config.dart';

class EmploymentHistoryScreen extends StatefulWidget {
  final bool isForced;
  const EmploymentHistoryScreen({super.key, this.isForced = false});

  @override
  State<EmploymentHistoryScreen> createState() => _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  String? status; // 'Employed', 'Unemployed', 'Rather Not Say'
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  
  // Maps Industry Name to ID based on your SQL Dump
  final Map<String, int> industryMap = {
    "Information Technology & Services": 1,
    "Education": 2,
    "Healthcare & Medical": 3,
    "Business Process Outsourcing (BPO)": 4,
    "Government & Public Sector": 5,
    "Finance & Banking": 6,
    "Hospitality & Tourism": 7,
    "Retail & E-commerce": 8,
    "Engineering & Construction": 9,
    "Real Estate": 10,
    "Manufacturing & Production": 11,
    "Food & Beverage (F&B)": 12,
    "Transportation & Logistics": 13,
    "Telecommunications": 14,
    "Media & Entertainment": 15,
    "Legal Services": 16,
    "Agriculture & Farming": 17,
    "Non-Profit & Volunteering": 18,
    "Automotive": 19,
    "Human Resources & Staffing": 20,
    "Other": 21
  };

  String selectedIndustryName = "Information Technology & Services";
  String relevantToCourse = "Yes";
  String timeToFirstJob = "0-6 months"; // Default value
  bool isSubmitting = false;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a status.")));
      return;
    }

    setState(() => isSubmitting = true);
    
    final user = Provider.of<UserProvider>(context, listen: false);
    
    try {
      final response = await http.post(
        Uri.parse(Config.submitEmploymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': user.studentId,
          'status': status,
          'job_title': status == 'Employed' ? _jobTitleController.text : null,
          'company': status == 'Employed' ? _companyController.text : null,
          'industry_id': status == 'Employed' ? industryMap[selectedIndustryName] : null, 
          'time_to_first_job': status == 'Employed' ? timeToFirstJob : 'Not Applicable',
          'relevance': status == 'Employed' ? relevantToCourse : null
        }),
      );

      final respData = json.decode(response.body);

      if (response.statusCode == 200 && respData['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History saved!")));
        Navigator.pop(context);
      } else {
        throw Exception(respData['message'] ?? "Unknown error");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkContent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text("Employment History", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        themeMode: theme.currentMode,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GlassContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Status", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: ['Employed', 'Unemployed', 'Rather Not Say'].map((s) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => status = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: status == s ? Colors.blue : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: status == s ? Colors.blue : Colors.transparent),
                          ),
                          child: Text(
                            s, 
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: status == s ? Colors.white : (isDark ? Colors.white70 : Colors.black87), 
                              fontWeight: FontWeight.bold, 
                              fontSize: 11
                            )
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  
                  if (status == 'Employed') ...[
                    const SizedBox(height: 24),
                    _inputField("Job Title", _jobTitleController, isDark),
                    _inputField("Company", _companyController, isDark),
                    
                    _dropdown("Industry", industryMap.keys.toList(), selectedIndustryName, (v) => setState(() => selectedIndustryName = v!), isDark),
                    
                    const SizedBox(height: 16),
                    
                    // Added Time to First Job Dropdown
                    _dropdown("Time to First Job", ["0-6 months", "7-12 months", "1+ year", "Not Applicable"], timeToFirstJob, (v) => setState(() => timeToFirstJob = v!), isDark),

                    const SizedBox(height: 20),
                    Text("Relevant to Course?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: ["Yes", "No", "Somewhat"].map((val) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => relevantToCourse = val),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: relevantToCourse == val ? Colors.blue : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: relevantToCourse == val ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent
                            ),
                            alignment: Alignment.center,
                            child: Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text("Save History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String current, Function(String?) onChange, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12)
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                isExpanded: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChange,
              ),
            ),
          )
        ],
      ),
    );
  }
}