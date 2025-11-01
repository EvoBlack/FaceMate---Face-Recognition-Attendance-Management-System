class AppConfig {
  static const String appName = 'FaceMate';
  static const String appVersion = '1.0.0';
  
  // API Configuration - Multiple connection methods
  static const String baseUrl = 'http://localhost:5000/api';  // ADB port forwarding (physical device)
  
  // Alternative URLs to try (in order of preference)
  static const List<String> fallbackUrls = [
    'http://localhost:5000/api',      // ADB port forwarding (primary)
    'http://127.0.0.1:5000/api',      // Localhost alternative
    'http://192.168.29.54:5000/api',  // Network IP
    'http://10.0.2.2:5000/api',       // Android emulator
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