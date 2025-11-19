import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';

class UserProvider with ChangeNotifier {
  // Core Fields
  int? _studentId;
  String? _studentNumber;
  String? _firstName;
  String? _lastName;
  int? _batchYear;
  String? _profilePicture;

  // Extended Profile Fields
  String? _program;
  String? _major;
  String? _email;
  String? _parents;
  String? _awards;
  String? _address;
  String? _birthdate;

  // Getters
  int? get studentId => _studentId;
  String? get studentNumber => _studentNumber;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  int? get batchYear => _batchYear;
  String? get profilePicture => _profilePicture;
  String? get program => _program;
  String? get major => _major;
  String? get email => _email;
  String? get parents => _parents;
  String? get awards => _awards;
  String? get address => _address;
  String? get birthdate => _birthdate;

  String? get fullName => (_firstName != null && _lastName != null) 
      ? "$_firstName $_lastName" 
      : _firstName;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getInt('student_id');
    _studentNumber = prefs.getString('student_number');
    _batchYear = prefs.getInt('batch_year');
    _profilePicture = prefs.getString('profile_photo');
    
    String? storedName = prefs.getString('full_name');
    if (storedName != null) _parseName(storedName);

    _program = prefs.getString('program') ?? "N/A";
    _major = prefs.getString('major') ?? "N/A";
    _email = prefs.getString('email') ?? "N/A";
    _parents = prefs.getString('parents') ?? "N/A";
    _awards = prefs.getString('awards') ?? "None";
    _address = prefs.getString('address') ?? "N/A";
    _birthdate = prefs.getString('birthdate') ?? "N/A";

    notifyListeners();
  }

  Future<void> setUser(int id, String number, String fullName, int batch, [String? profilePhoto]) async {
    _studentId = id;
    _studentNumber = number;
    _batchYear = batch;
    _profilePicture = profilePhoto;
    _parseName(fullName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_id', id);
    await prefs.setString('student_number', number);
    await prefs.setString('full_name', fullName);
    await prefs.setInt('batch_year', batch);
    if (profilePhoto != null) {
      await prefs.setString('profile_photo', profilePhoto);
    }
    notifyListeners();
  }
  
  void _parseName(String fullName) {
    List<String> parts = fullName.trim().split(' ');
    if (parts.isNotEmpty) {
      _firstName = parts.first;
      _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    } else {
      _firstName = fullName;
      _lastName = '';
    }
  }

  Future<void> refreshProfile() async {
    if (_studentId == null) return;
    
    try {
      print("Fetching profile for ID: $_studentId"); // Debug log
      final response = await http.post(
        Uri.parse(Config.getStudentProfileUrl),
        body: json.encode({'student_id': _studentId}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debug log to see what comes back

        if (data['status'] == 'success') {
          final info = data['data'];
          
          String newName = "${info['fname']} ${info['lname']}";
          int newBatch = int.tryParse(info['batch_year'].toString()) ?? 0;
          
          // Ensure profile photo is null if empty string comes back
          String? newPhoto = (info['profile_photo'] != null && info['profile_photo'].toString().isNotEmpty) 
              ? info['profile_photo'] 
              : null;
          
          // Update Core User Data
          await setUser(_studentId!, _studentNumber ?? '', newName, newBatch, newPhoto);
          
          // Update Extended Fields
          _program = info['department_name'] ?? "N/A"; 
          _major = info['major_name'] ?? "N/A";
          _email = info['email'] ?? "N/A";
          _parents = info['parents_display'] ?? "N/A";
          _awards = info['awards'] ?? "None";
          _address = info['full_address'] ?? "N/A";
          _birthdate = info['dob'] ?? "N/A";

          // Save Extended Data to Preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('program', _program!);
          await prefs.setString('major', _major!);
          await prefs.setString('email', _email!);
          await prefs.setString('parents', _parents!);
          await prefs.setString('awards', _awards!);
          await prefs.setString('address', _address!);
          await prefs.setString('birthdate', _birthdate!);

          notifyListeners();
        }
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }
  }

  Future<void> logout() async {
    _studentId = null;
    // ... (reset other fields to null)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}