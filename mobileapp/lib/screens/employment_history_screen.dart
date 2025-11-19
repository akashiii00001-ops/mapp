import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';
import 'package:mobileapp/providers/user_provider.dart';
import 'package:provider/provider.dart';

class EmploymentHistoryScreen extends StatefulWidget {
  final bool isForced; // If true, back button is hidden until submission
  const EmploymentHistoryScreen({super.key, this.isForced = false});

  @override
  State<EmploymentHistoryScreen> createState() => _EmploymentHistoryScreenState();
}

class _EmploymentHistoryScreenState extends State<EmploymentHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Fixed Status Options
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
      debugPrint("Error fetching industries: $e");
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
      // Send empty strings if not employed
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record updated successfully!")));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isForced,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Employment History"),
          automaticallyImplyLeading: !widget.isForced,
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Employment Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => status = val!),
                  ),
                  const SizedBox(height: 20),
                  
                  // Only show details if Employed
                  if (status == 'Employed') ...[
                    TextFormField(
                      controller: jobController,
                      decoration: const InputDecoration(labelText: "Job Title", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: companyController,
                      decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: "Industry", border: OutlineInputBorder()),
                      value: selectedIndustry,
                      items: industries.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem(
                          value: item['industry_id'].toString(),
                          child: Text(item['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedIndustry = val),
                      validator: (v) => v == null ? "Please select an industry" : null,
                    ),
                    const SizedBox(height: 15),
                    const Text("Is this relevant to your course?", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: RadioListTile<String>(title: const Text("Yes"), value: "Yes", groupValue: relevance, onChanged: (v) => setState(()=>relevance=v))),
                        Expanded(child: RadioListTile<String>(title: const Text("No"), value: "No", groupValue: relevance, onChanged: (v) => setState(()=>relevance=v))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: timeToFirstJob,
                      decoration: const InputDecoration(labelText: "Time to first job", border: OutlineInputBorder()),
                      items: ['0-6 months', '7-12 months', '1+ year', 'Not Applicable']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => timeToFirstJob = val!),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0033A0)),
                      child: isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Submit Record", style: TextStyle(color: Colors.white, fontSize: 16)),
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