class Config {
  // ==================================================================
  //  CONNECTION SETTINGS (Toggle these lines)
  // ==================================================================
  
  // OPTION A: Use this for Android Emulator on Laptop
  static const String baseUrl = 'http://10.0.2.2/psu_yearbook_api';

  // OPTION B: Use this for Physical Phone (Pocket Wi-Fi / Router)
  // Replace 192.168.x.x with your Laptop's IPv4 address from ipconfig
  // static const String baseUrl = 'http://192.168.1.5/psu_yearbook_api';

  // ==================================================================
  //  API ENDPOINTS
  // ==================================================================

  // --- Auth & Security (EXISTING) ---
  static const String loginUrl = '$baseUrl/student_login.php';
  static const String recoveryStatusUrl = '$baseUrl/check_recovery_status.php';
  static const String verifySecurityUrl = '$baseUrl/verify_security.php';
  static const String email2faUrl = '$baseUrl/setup_and_verify.php';
  static const String forgotPasswordUrl = '$baseUrl/forgot_password_api.php';
  
  // --- Home & Employment (EXISTING) ---
  static const String getFeedsUrl = '$baseUrl/get_home_feeds.php';
  static const String getIndustriesUrl = '$baseUrl/get_industries.php';
  static const String submitEmploymentUrl = '$baseUrl/submit_employment_history.php';
  static const String checkEmploymentStatusUrl = '$baseUrl/check_employment_status.php';

  // --- Profile & Settings (NEW - Added for this update) ---
  static const String getStudentProfileUrl = '$baseUrl/get_student_profile.php';
  static const String updateSettingsUrl = '$baseUrl/update_settings.php';
}