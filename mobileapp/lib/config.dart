class Config {
  // ==================================================================
  //  CONNECTION SETTINGS 
  // ==================================================================
  
  // DOMAIN: Use '10.0.2.2' for Android Emulator. 
  // Use your PC's IP (e.g., 192.168.x.x) for physical phones.
  static const String domain = 'http://10.0.2.2'; 
  
  // 1. API BASE URL (Where your PHP files are)
  // Based on your original file, this is likely directly in htdocs
  static const String baseUrl = '$domain/psu_yearbook_api';
  static const String apiUrl = baseUrl;

  // 2. IMAGES BASE URL (Where your photos are)
  // You mentioned these are inside the CAPSTONE folder
  static const String uploadsUrl = '$domain/CAPSTONE/uploads';
  
  // Helper paths for specific image types
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
}