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

  // Extended Profile Fields (Initialized to null to avoid fake data)
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

    // Load extended fields (Defaults to NULL if not set)
    _program = prefs.getString('program');
    _major = prefs.getString('major');
    _email = prefs.getString('email');
    _parents = prefs.getString('parents');
    _awards = prefs.getString('awards');
    _address = prefs.getString('address');
    _birthdate = prefs.getString('birthdate');

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
          String? newPhoto = info['profile_photo'];
          
          await setUser(_studentId!, _studentNumber ?? '', newName, newBatch, newPhoto);
          
          // Map API fields strictly. If empty in DB, they stay empty.
          _program = info['department_name']; 
          _major = info['major_name'];
          _email = info['email'];
          
          // Handle Parents (API sends "N/A" if empty, or we can handle it here)
          _parents = (info['parents_display'] == "N/A" || info['parents_display'] == "") ? null : info['parents_display'];
          _awards = (info['awards'] == "None" || info['awards'] == "") ? null : info['awards'];
          _address = (info['full_address'] == "N/A" || info['full_address'] == "") ? null : info['full_address'];
          _birthdate = info['dob'];

          // Save Extended Data
          final prefs = await SharedPreferences.getInstance();
          if (_program != null) await prefs.setString('program', _program!);
          if (_major != null) await prefs.setString('major', _major!);
          if (_email != null) await prefs.setString('email', _email!);
          if (_parents != null) await prefs.setString('parents', _parents!);
          if (_awards != null) await prefs.setString('awards', _awards!);
          if (_address != null) await prefs.setString('address', _address!);
          if (_birthdate != null) await prefs.setString('birthdate', _birthdate!);

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }
  }

  Future<void> logout() async {
    _studentId = null;
    _studentNumber = null;
    _firstName = null;
    _lastName = null;
    _batchYear = null;
    _profilePicture = null;
    _program = null;
    _major = null;
    _email = null;
    _parents = null;
    _awards = null;
    _address = null;
    _birthdate = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}