import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';

class UserProvider with ChangeNotifier {
  int? _studentId;
  String? _studentNumber;
  String? _fullName;
  int? _batchYear;

  int? get studentId => _studentId;
  String? get studentNumber => _studentNumber;
  String? get fullName => _fullName;
  int? get batchYear => _batchYear;

  // Load user data from phone storage on app start
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getInt('student_id');
    _studentNumber = prefs.getString('student_number');
    _fullName = prefs.getString('full_name');
    _batchYear = prefs.getInt('batch_year');
    notifyListeners();
  }

  // Save user data after login
  Future<void> setUser(int id, String number, String name, int batch) async {
    _studentId = id;
    _studentNumber = number;
    _fullName = name;
    _batchYear = batch;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_id', id);
    await prefs.setString('student_number', number);
    await prefs.setString('full_name', name);
    await prefs.setInt('batch_year', batch);
    
    notifyListeners();
  }
  
  // Force refresh profile data from API (Useful if name/photo changes)
  Future<void> refreshProfile() async {
    if (_studentId == null) return;
    
    try {
      final response = await http.post(
        Uri.parse(Config.getStudentProfileUrl),
        body: json.encode({'student_id': _studentId}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final info = data['data'];
          String newName = "${info['fname']} ${info['lname']}";
          int newBatch = int.tryParse(info['batch_year'].toString()) ?? 0;
          
          // Update local state
          setUser(_studentId!, _studentNumber ?? '', newName, newBatch);
        }
      }
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }
  }

  Future<void> logout() async {
    _studentId = null;
    _studentNumber = null;
    _fullName = null;
    _batchYear = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}