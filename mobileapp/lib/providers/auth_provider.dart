import 'package:flutter/material.dart';

// Enum to represent the steps
enum AuthStep { login, identity, email, home }

class AuthProvider with ChangeNotifier {
  AuthStep _currentStep = AuthStep.login;

  AuthStep get currentStep => _currentStep;
  
  // Calculate progress
  double get progress {
    switch (_currentStep) {
      case AuthStep.login:
        return 0.25;
      case AuthStep.identity:
        return 0.5;
      case AuthStep.email:
        return 0.75;
      case AuthStep.home:
        return 1.0;
    }
  }

  void setStep(AuthStep step) {
    _currentStep = step;
    notifyListeners();
  }

  // FIX: Added logout method
  void logout() {
    _currentStep = AuthStep.login;
    notifyListeners();
  }
}