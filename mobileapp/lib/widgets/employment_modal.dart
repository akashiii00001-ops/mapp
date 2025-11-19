import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';

class EmploymentModal extends StatefulWidget {
  final String studentId;
  const EmploymentModal({super.key, required this.studentId});

  @override
  State<EmploymentModal> createState() => _EmploymentModalState();
}

class _EmploymentModalState extends State<EmploymentModal> {
  final _formKey = GlobalKey<FormState>();
  String status = 'Unemployed';
  String? relevance = 'No';
  String timeToFirstJob = 'Not Applicable';
  
  final TextEditingController jobController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  
  List<dynamic> industries = [];
  String? selectedIndustry;
  bool isSubmitting = false;

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
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching industries: $e");
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final body = {
      'student_id': widget.studentId,
      'status': status,
      'job_title': jobController.text,
      'company': companyController.text,
      'industry_id': selectedIndustry,
      'time_to_first_job': timeToFirstJob,
      'relevance': relevance
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
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for updating your record!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['message']}")));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Help us track our graduates!"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Are you currently employed?"),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Employed', 'Unemployed', 'Not Specified']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => status = val!),
              ),
              if (status == 'Employed') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: jobController,
                  decoration: const InputDecoration(labelText: "Job Title"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: "Company Name"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                DropdownButtonFormField(
                  hint: const Text("Select Industry"),
                  items: industries.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem(
                      value: item['industry_id'].toString(),
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedIndustry = val),
                ),
                const SizedBox(height: 10),
                const Text("Is this relevant to your course?"),
                // Note: RadioListTile is standard. If you strictly need RadioGroup, it requires specific version wrappers
                // For now, we assume standard widget usage is acceptable despite the lint.
                Row(
                  children: [
                    Expanded(child: RadioListTile<String>(
                      title: const Text("Yes"), 
                      value: "Yes", 
                      groupValue: relevance, 
                      onChanged: (v) => setState(()=>relevance=v)
                    )),
                    Expanded(child: RadioListTile<String>(
                      title: const Text("No"), 
                      value: "No", 
                      groupValue: relevance, 
                      onChanged: (v) => setState(()=>relevance=v)
                    )),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: timeToFirstJob,
                  decoration: const InputDecoration(labelText: "Time to first job"),
                  items: ['0-6 months', '7-12 months', '1+ year', 'Not Applicable']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => timeToFirstJob = val!),
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : _submitData,
          child: isSubmitting ? const CircularProgressIndicator() : const Text("Submit"),
        )
      ],
    );
  }
}