import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added Import

class UserProvider with ChangeNotifier {
  int? _studentId;
  String? _studentNumber;
  String? _fullName;
  int? _batchYear; // Added

  int? get studentId => _studentId;
  String? get studentNumber => _studentNumber;
  String? get fullName => _fullName;
  int? get batchYear => _batchYear; // Added Getter

  // Load user data from storage on app start
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getInt('student_id');
    _studentNumber = prefs.getString('student_number');
    _fullName = prefs.getString('full_name');
    _batchYear = prefs.getInt('batch_year'); // Load batch
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
  
  Future<void> fetchUserProfile() async {
    notifyListeners();
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