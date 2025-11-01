import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> login(String username, String password) async {
    try {
      // Test connection first
      final isConnected = await apiClient.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to server. Please check if the backend is running and ADB port forwarding is set up.');
      }

      final response = await apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        final errorMessage = response.data?['error'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Connection')) {
        throw Exception('Connection error: Please ensure the backend server is running and accessible.');
      }
      rethrow;
    }
  }
}