import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:provider/provider.dart';

class EmploymentHistoryScreen extends StatefulWidget {
  final bool isMandatory;
  const EmploymentHistoryScreen({super.key, this.isMandatory = false});

  @override
  State<EmploymentHistoryScreen> createState() => _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _status = 'Employed';
  String? _jobTitle;
  String? _company;
  String? _selectedIndustry;
  String _timeToJob = '0-6 months';
  String _relevance = 'Yes';
  List<dynamic> _industries = [];
  bool _isLoading = false;

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
        });
      }
    } catch (e) {
      print("Error fetching industries: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final userId = context.read<UserProvider>().studentId;

    try {
      final response = await http.post(
        Uri.parse(Config.submitEmploymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': userId,
          'status': _status,
          'job_title': _jobTitle,
          'company': _company,
          'industry_id': _selectedIndustry,
          'time_to_first_job': _timeToJob,
          'relevant': _relevance,
        }),
      );

      final resData = json.decode(response.body);
      if (resData['status'] == 'success') {
        if (widget.isMandatory) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employment history updated!')),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${resData['message']}')),
          );
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection error')),
          );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isMandatory,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Employment History"),
          automaticallyImplyLeading: !widget.isMandatory,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isMandatory)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber),
                              SizedBox(width: 10),
                              Expanded(child: Text("Help us track our graduates! Please update your status to proceed.")),
                            ],
                          ),
                        ),
                      
                      const Text("Are you currently employed?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: _status,
                        items: ['Employed', 'Unemployed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _status = val!),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 15),

                      if (_status == 'Employed') ...[
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onSaved: (v) => _jobTitle = v,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          onSaved: (v) => _company = v,
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Industry', border: OutlineInputBorder()),
                          items: _industries.map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem(
                              value: item['industry_id'].toString(),
                              child: Text(item['name']),
                            );
                          }).toList(),
                          onChanged: (val) => _selectedIndustry = val,
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 15),
                        const Text("Time to land first job:", style: TextStyle(fontWeight: FontWeight.bold)),
                         DropdownButtonFormField<String>(
                          value: _timeToJob,
                          items: ['0-6 months', '7-12 months', '1+ year', 'Not Applicable'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => _timeToJob = val!,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 15),
                         const Text("Is this relevant to your course?", style: TextStyle(fontWeight: FontWeight.bold)),
                         DropdownButtonFormField<String>(
                          value: _relevance,
                          items: ['Yes', 'No', 'Somewhat'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => _relevance = val!,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ],

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text("Submit Record"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}