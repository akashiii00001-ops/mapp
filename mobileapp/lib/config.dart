class Config {
  // ==================================================================
  //  CONNECTION SETTINGS 
  // ==================================================================
  
  // DOMAIN: Use '10.0.2.2' for Android Emulator. 
  // Use your PC's IP (e.g., 192.168.x.x) for physical phones.
  static const String domain = 'http://10.0.2.2'; 
  
  // 1. API BASE URL (Where your PHP files are)
  static const String baseUrl = '$domain/psu_yearbook_api';
  static const String apiUrl = baseUrl;

  // 2. PROJECT ROOT URL (Where your CAPSTONE folder is)
  // This matches your path: C:\xampp\htdocs\CAPSTONE
  static const String projectRootUrl = '$domain/CAPSTONE';

  // 3. SPECIFIC UPLOADS FOLDERS
  // These are fallbacks. The code in HomeScreen now handles relative paths dynamically.
  static const String uploadsUrl = '$projectRootUrl/uploads';
  static const String announcementImgUrl = '$uploadsUrl/announcements';
  static const String eventImgUrl = '$uploadsUrl/events';
  static const String jobImgUrl = '$uploadsUrl/jobs';
  static const String profileImgUrl = '$uploadsUrl/alumni_photos';

  // ==================================================================
  //  API ENDPOINTS
  // ==================================================================
  static const String loginUrl = '$baseUrl/student_login.php';
  static const String getHomeDataUrl = '$baseUrl/get_home_data.php';
  static const String getStudentProfileUrl = '$baseUrl/get_student_profile.php';
  
  // Employment
  static const String getIndustriesUrl = '$baseUrl/get_industries.php';
  static const String checkEmploymentStatusUrl = '$baseUrl/check_employment_status.php';
  static const String submitEmploymentUrl = '$baseUrl/submit_employment_history.php';
  
  // Settings & Account
  static const String updateSettingsUrl = '$baseUrl/update_account.php';
  static const String recoveryStatusUrl = '$baseUrl/check_recovery_status.php';
  static const String verifySecurityUrl = '$baseUrl/verify_security.php';
  static const String email2faUrl = '$baseUrl/setup_and_verify.php';
  static const String forgotPasswordUrl = '$baseUrl/forgot_password_api.php';
  
  // NEW: Added for the in-app security flow (Change Pass/Email with OTP)
  static const String settingsActionUrl = '$baseUrl/settings_actions.php';
}