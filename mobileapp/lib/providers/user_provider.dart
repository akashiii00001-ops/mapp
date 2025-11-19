import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileapp/config.dart';

class UserProvider extends ChangeNotifier {
  int? _studentId;
  String? _fullName;
  String? _email;
  String? _batchYear;
  String? _profilePhoto;

  int? get studentId => _studentId;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get batchYear => _batchYear;

  void setUser(int id) {
    _studentId = id;
    fetchUserProfile();
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_studentId == null) return;
    
    try {
      final response = await http.post(
        Uri.parse(Config.getStudentProfileUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'student_id': _studentId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final info = data['data'];
          _fullName = "${info['fname']} ${info['lname']}";
          _email = info['email'];
          _batchYear = info['batch_year'].toString();
          _profilePhoto = info['profile_photo'];
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }
  
  void logout() {
    _studentId = null;
    _fullName = null;
    _email = null;
    _batchYear = null;
    notifyListeners();
  }
}