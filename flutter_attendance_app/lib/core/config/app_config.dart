class AppConfig {
  static const String appName = 'FaceMate';
  static const String appVersion = '1.0.0';
  
  // API Configuration - Using deployed backend on HuggingFace
  static const String baseUrl = 'https://evoblackk-facemate-backend.hf.space/api';
  
  // Alternative URLs to try (in order of preference)
  static const List<String> fallbackUrls = [
    'https://evoblackk-facemate-backend.hf.space/api',  // Production backend (HuggingFace)
    'http://localhost:5000/api',                         // Local development fallback
    'http://127.0.0.1:5000/api',                         // Localhost alternative
    'http://10.0.2.2:5000/api',                          // Android emulator
  ];
  
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  
  // Face Recognition Configuration
  static const double faceRecognitionThreshold = 0.6;
  static const int maxTrainingImages = 100;
  static const Duration cameraTimeout = Duration(seconds: 30);
  
  // Database Configuration
  static const String dbName = 'attendance_app.db';
  static const int dbVersion = 1;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String faceEncodingsKey = 'face_encodings';
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}