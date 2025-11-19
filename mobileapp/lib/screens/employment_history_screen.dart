import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobileapp/config.dart';
import 'package:mobileapp/theme.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:mobileapp/widgets/loading_dialog.dart';

class EmploymentHistoryScreen extends StatefulWidget {
  final bool isMandatory;
  const EmploymentHistoryScreen({super.key, this.isMandatory = false});

  @override
  State<EmploymentHistoryScreen> createState() => _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<dynamic> _industries = [];

  // Form Data
  String _status = 'Employed';
  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _companyCtrl = TextEditingController();
  String? _selectedIndustry;
  String _timeToJob = '0-6 months';
  String _relevance = 'Yes';

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  Future<void> _fetchIndustries() async {
    try {
      final response = await http.get(Uri.parse(Config.getIndustriesUrl));
      if (response.statusCode == 200) {
        setState(() {
          _industries = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    showLoadingDialog(context, "Saving...");
    final user = context.read<UserProvider>();

    try {
      final response = await http.post(
        Uri.parse(Config.submitEmploymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': user.studentId,
          'status': _status,
          'job_title': _jobCtrl.text,
          'company': _companyCtrl.text,
          'industry_id': _selectedIndustry,
          'time_to_first_job': _timeToJob,
          'relevance': _relevance,
        }),
      );

      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['status'] == 'success') {
          if (widget.isMandatory) {
             Navigator.pop(context); // Close Mandatory Dialog
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record Updated!")));
             Navigator.pop(context); // Go back to Home
          }
        } else {
          _showError(resData['message'] ?? "Failed to save");
        }
      }
    } catch (e) {
      Navigator.pop(context);
      _showError("Connection Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isMandatory 
        ? null 
        : AppBar(title: const Text("Update Employment")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isMandatory) ...[
                    const Text("Help Us Track Our Graduates!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                    const SizedBox(height: 8),
                    const Text("Are you currently employed?", style: TextStyle(fontSize: 16)),
                    const Divider(height: 30),
                  ],

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: "Employment Status", border: OutlineInputBorder()),
                    items: ['Employed', 'Unemployed'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 20),

                  if (_status == 'Employed') ...[
                    TextFormField(
                      controller: _jobCtrl,
                      decoration: const InputDecoration(labelText: "Job Title", border: OutlineInputBorder(), prefixIcon: Icon(Icons.work)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedIndustry,
                      decoration: const InputDecoration(labelText: "Industry", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                      items: _industries.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem(value: item['industry_id'].toString(), child: Text(item['name']));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedIndustry = v),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 15),

                    const Text("How long did it take to find your first job?"),
                    DropdownButtonFormField<String>(
                      value: _timeToJob,
                      items: ['0-6 months', '7-12 months', '1+ year', 'Not Applicable'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _timeToJob = v!),
                    ),
                    const SizedBox(height: 15),

                    const Text("Is it relevant to your course?"),
                    Row(
                      children: [
                        Radio(value: 'Yes', groupValue: _relevance, onChanged: (v) => setState(() => _relevance = v.toString())), const Text("Yes"),
                        Radio(value: 'No', groupValue: _relevance, onChanged: (v) => setState(() => _relevance = v.toString())), const Text("No"),
                        Radio(value: 'Somewhat', groupValue: _relevance, onChanged: (v) => setState(() => _relevance = v.toString())), const Text("Somewhat"),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submit,
                      child: const Text("Submit Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}