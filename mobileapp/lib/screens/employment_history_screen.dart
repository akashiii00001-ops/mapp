import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmploymentHistoryScreen extends StatefulWidget {
  final bool isForced; 
  const EmploymentHistoryScreen({super.key, this.isForced = false});

  @override
  State<EmploymentHistoryScreen> createState() => _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final List<String> statusOptions = ['Employed', 'Unemployed', 'Not Specified'];
  String status = 'Employed'; 

  String? relevance = 'No';
  String timeToFirstJob = 'Not Applicable';
  
  final TextEditingController jobController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  
  List<dynamic> industries = [];
  String? selectedIndustry;
  bool isSubmitting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  Future<void> _fetchIndustries() async {
    try {
      final res = await http.get(Uri.parse(Config.getIndustriesUrl));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            industries = json.decode(res.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final studentId = userProvider.studentId;

    final body = {
      'student_id': studentId,
      'status': status,
      'job_title': status == 'Employed' ? jobController.text : '',
      'company': status == 'Employed' ? companyController.text : '',
      'industry_id': status == 'Employed' ? selectedIndustry : null,
      'time_to_first_job': status == 'Employed' ? timeToFirstJob : 'Not Applicable',
      'relevance': status == 'Employed' ? relevance : 'No'
    };

    try {
      final res = await http.post(
        Uri.parse(Config.submitEmploymentUrl),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"},
      );
      
      if (!mounted) return;

      final result = json.decode(res.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Record updated successfully!")));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error: ${result['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F172A);
    
    return PopScope(
      canPop: !widget.isForced,
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          title: const Text("Employment Status", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: !widget.isForced,
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Current Status", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: statusOptions.map((s) {
                                final isSelected = status == s;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => status = s),
                                    child: AnimatedContainer(
                                      duration: 200.ms,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 8)] : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        s,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 12
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),
                            
                            if (status == 'Employed') ...[
                              _buildGlassTextField("Job Title", jobController, FontAwesomeIcons.briefcase),
                              const SizedBox(height: 16),
                              _buildGlassTextField("Company Name", companyController, FontAwesomeIcons.building),
                              const SizedBox(height: 16),
                              
                              _buildGlassDropdown(
                                "Industry",
                                selectedIndustry,
                                industries.map<DropdownMenuItem<String>>((item) {
                                  return DropdownMenuItem(
                                    value: item['industry_id'].toString(),
                                    child: Text(item['name'], style: const TextStyle(color: Colors.white)), 
                                  );
                                }).toList(),
                                (val) => setState(() => selectedIndustry = val),
                              ),

                              const SizedBox(height: 24),
                              const Text("Is this relevant to your course?", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildRadioBtn("Yes"),
                                  const SizedBox(width: 12),
                                  _buildRadioBtn("No"),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              _buildGlassDropdown(
                                "Time to first job",
                                timeToFirstJob,
                                ['0-6 months', '7-12 months', '1+ year', 'Not Applicable']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                                    .toList(),
                                (val) => setState(() => timeToFirstJob = val!),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text("Save History", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildGlassTextField(String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildGlassDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E293B), 
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => status == 'Employed' && v == null ? "Required" : null,
    );
  }

  Widget _buildRadioBtn(String val) {
    bool isSelected = relevance == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => relevance = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(val, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}