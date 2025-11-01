import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'dart:io';
import '../config/app_config.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) => developer.log('API: $obj', name: 'ApiClient'),
    ));
    
    // Add retry interceptor for connection failures
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          developer.log('Retrying request due to connection error', name: 'ApiClient');
          try {
            final response = await _retryRequest(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            developer.log('Retry failed: $e', name: 'ApiClient');
          }
        }
        handler.next(error);
      },
    ));
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    developer.log('API base URL updated to: $newBaseUrl', name: 'ApiClient');
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           (error.error is SocketException);
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    // Try to find a working URL
    for (String fallbackUrl in AppConfig.fallbackUrls) {
      try {
        final testDio = Dio(BaseOptions(
          baseUrl: fallbackUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        // Test the connection first
        await testDio.get('/health');
        
        // If successful, update main dio and retry original request
        _dio.options.baseUrl = fallbackUrl;
        developer.log('Switched to working URL: $fallbackUrl', name: 'ApiClient');
        
        return await _dio.fetch(requestOptions);
      } catch (e) {
        developer.log('Fallback URL $fallbackUrl failed: $e', name: 'ApiClient');
        continue;
      }
    }
    
    throw DioException(
      requestOptions: requestOptions,
      error: 'All connection attempts failed',
      type: DioExceptionType.connectionError,
    );
  }

  Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    // Test each possible URL
    for (String url in AppConfig.fallbackUrls) {
      try {
        final testDio = Dio(BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        final stopwatch = Stopwatch()..start();
        final response = await testDio.get('/health');
        stopwatch.stop();
        
        results[url] = {
          'status': 'success',
          'statusCode': response.statusCode,
          'responseTime': '${stopwatch.elapsedMilliseconds}ms',
          'data': response.data,
        };
      } catch (e) {
        results[url] = {
          'status': 'failed',
          'error': e.toString(),
        };
      }
    }
    
    return results;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      developer.log('GET: ${_dio.options.baseUrl}$path', name: 'ApiClient');
      final response = await _dio.get(path, queryParameters: queryParameters);
      developer.log('GET Response: ${response.statusCode}', name: 'ApiClient');
      return response;
    } on DioException catch (e) {
      developer.log('GET Error: ${e.type} - ${e.message}', name: 'ApiClient');
      developer.log('Request URL: ${e.requestOptions.uri}', name: 'ApiClient');
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      developer.log('POST: ${_dio.options.baseUrl}$path', name: 'ApiClient');
      developer.log('POST Data: $data', name: 'ApiClient');
      final response = await _dio.post(path, data: data);
      developer.log('POST Response: ${response.statusCode}', name: 'ApiClient');
      return response;
    } on DioException catch (e) {
      developer.log('POST Error: ${e.type} - ${e.message}', name: 'ApiClient');
      developer.log('Request URL: ${e.requestOptions.uri}', name: 'ApiClient');
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> testConnection() async {
    // Try current base URL first
    try {
      final response = await _dio.get('/health', options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      if (response.statusCode == 200) {
        developer.log('Connection successful with current URL: ${_dio.options.baseUrl}', name: 'ApiClient');
        return true;
      }
    } catch (e) {
      developer.log('Connection test failed with current URL: $e', name: 'ApiClient');
    }

    // Try fallback URLs
    for (String fallbackUrl in AppConfig.fallbackUrls) {
      if (fallbackUrl == _dio.options.baseUrl) continue; // Skip current URL
      
      try {
        developer.log('Trying fallback URL: $fallbackUrl', name: 'ApiClient');
        final testDio = Dio(BaseOptions(
          baseUrl: fallbackUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        final response = await testDio.get('/health');
        if (response.statusCode == 200) {
          developer.log('Connection successful with fallback URL: $fallbackUrl', name: 'ApiClient');
          // Update the main dio instance to use this URL
          _dio.options.baseUrl = fallbackUrl;
          return true;
        }
      } catch (e) {
        developer.log('Fallback URL $fallbackUrl failed: $e', name: 'ApiClient');
      }
    }
    
    return false;
  }

  Exception _handleError(DioException error) {
    developer.log('API Error: ${error.type} - ${error.message}', name: 'ApiClient');
    developer.log('Request URL: ${error.requestOptions.uri}', name: 'ApiClient');
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Connection timeout. Please check your internet connection and try again.');
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['error'] ?? 'Server error';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check if the server is running and accessible.');
      default:
        return Exception('Network error: ${error.message}');
    }
  }
}