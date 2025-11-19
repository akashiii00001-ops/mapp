class Config {
  // ==================================================================
  //  CONNECTION SETTINGS 
  // ==================================================================
  
  // OPTION A: Use this for Android Emulator
  static const String baseUrl = 'http://10.0.2.2/psu_yearbook_api';

  // OPTION B: Use this for Physical Phone (Update IP)
  // static const String baseUrl = 'http://192.168.1.5/psu_yearbook_api';

  // Alias for baseUrl to fix "getter apiUrl isn't defined" error
  static const String apiUrl = baseUrl;

  // ==================================================================
  //  API ENDPOINTS
  // ==================================================================

  static const String loginUrl = '$baseUrl/student_login.php';
  static const String recoveryStatusUrl = '$baseUrl/check_recovery_status.php';
  static const String verifySecurityUrl = '$baseUrl/verify_security.php';
  static const String email2faUrl = '$baseUrl/setup_and_verify.php';
  static const String forgotPasswordUrl = '$baseUrl/forgot_password_api.php';
  static const String updateSettingsUrl = '$baseUrl/update_settings.php';

  static const String getFeedsUrl = '$baseUrl/get_home_feeds.php';
  static const String getStudentProfileUrl = '$baseUrl/get_student_profile.php';

  static const String getIndustriesUrl = '$baseUrl/get_industries.php';
  static const String checkEmploymentStatusUrl = '$baseUrl/check_employment_status.php';
  static const String submitEmploymentUrl = '$baseUrl/submit_employment_history.php';
}