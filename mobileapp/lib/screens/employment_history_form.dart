import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';

class EmploymentHistoryForm extends StatefulWidget {
  final int studentId;
  const EmploymentHistoryForm({super.key, required this.studentId});

  @override
  State<EmploymentHistoryForm> createState() => _EmploymentHistoryFormState();
}

class _EmploymentHistoryFormState extends State<EmploymentHistoryForm> {
  bool isEmployed = false;
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  
  // Industry Data
  List<dynamic> _industryList = [];
  String? _selectedIndustryId;
  bool _isLoadingIndustries = true;

  String _timeToFirstJob = '0-6 months';
  String _relevantToCourse = 'Yes';

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  // --- API CALL: Get Industries ---
  Future<void> _fetchIndustries() async {
    try {
      final response = await http.get(Uri.parse(Config.getIndustriesUrl));
      if (response.statusCode == 200) {
        setState(() {
          _industryList = json.decode(response.body);
          _isLoadingIndustries = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading industries: $e");
    }
  }

  // --- API CALL: Submit Data ---
  Future<void> _submitData() async {
    try {
      final response = await http.post(
        Uri.parse(Config.submitEmploymentUrl),
        body: json.encode({
          'student_id': widget.studentId,
          'status': isEmployed ? 'Employed' : 'Unemployed',
          'job_title': isEmployed ? _jobTitleController.text : null,
          'company': isEmployed ? _companyController.text : null,
          'industry_id': isEmployed ? _selectedIndustryId : null,
          'time_to_first_job': _timeToFirstJob,
          'relevant': _relevantToCourse,
        }),
      );

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record updated successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Employment History"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Help us track our graduates! Are you currently employed?"),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(isEmployed ? "Employed" : "Unemployed", style: const TextStyle(fontWeight: FontWeight.bold)),
              value: isEmployed,
              onChanged: (val) => setState(() => isEmployed = val),
            ),
            if (isEmployed) ...[
              const Divider(),
              TextField(controller: _jobTitleController, decoration: const InputDecoration(labelText: "Job Title")),
              const SizedBox(height: 8),
              TextField(controller: _companyController, decoration: const InputDecoration(labelText: "Company Name")),
              const SizedBox(height: 8),
              _isLoadingIndustries
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedIndustryId,
                      hint: const Text("Select Industry"),
                      items: _industryList.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['industry_id'].toString(),
                          child: Text(item['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedIndustryId = val),
                    ),
              const SizedBox(height: 16),
              const Text("Time to find first job:"),
              DropdownButton<String>(
                value: _timeToFirstJob,
                isExpanded: true,
                items: ['0-6 months', '7-12 months', '1+ year', 'Not Applicable']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _timeToFirstJob = val!),
              ),
              const SizedBox(height: 16),
              const Text("Related to your course?"),
              DropdownButton<String>(
                value: _relevantToCourse,
                isExpanded: true,
                items: ['Yes', 'No', 'Somewhat']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _relevantToCourse = val!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitData, child: const Text("Submit")),
      ],
    );
  }
}