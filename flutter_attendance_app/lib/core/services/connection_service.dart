import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import '../network/api_client.dart';
import '../config/app_config.dart';

class ConnectionService {
  final ApiClient _apiClient;
  Timer? _connectionTimer;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  
  ConnectionService(this._apiClient);
  
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  
  void startMonitoring() {
    // Test connection immediately
    _testConnection();
    
    // Then test every 15 seconds for more responsive connection monitoring
    _connectionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _testConnection();
    });
  }
  
  void stopMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }
  
  Future<void> _testConnection() async {
    try {
      final connected = await _testMultipleUrls();
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectionController.add(_isConnected);
        developer.log('Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}', name: 'ConnectionService');
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectionController.add(_isConnected);
        developer.log('Connection lost: $e', name: 'ConnectionService');
      }
    }
  }

  Future<bool> _testMultipleUrls() async {
    // Try each URL in the fallback list
    for (String url in AppConfig.fallbackUrls) {
      try {
        final result = await _testSpecificUrl(url);
        if (result) {
          // Update API client to use working URL
          _apiClient.updateBaseUrl(url);
          developer.log('Using working URL: $url', name: 'ConnectionService');
          return true;
        }
      } catch (e) {
        developer.log('URL $url failed: $e', name: 'ConnectionService');
        continue;
      }
    }
    return false;
  }

  Future<bool> _testSpecificUrl(String baseUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      
      final uri = Uri.parse('$baseUrl/health'.replaceAll('/api/health', '/health'));
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> testConnectionOnce() async {
    await _testConnection();
    return _isConnected;
  }
  
  void dispose() {
    stopMonitoring();
    _connectionController.close();
  }
}