import '../../../../core/network/api_client.dart';

class StudentDatasource {
  final ApiClient apiClient;

  StudentDatasource({required this.apiClient});

  Future<Map<String, dynamic>> getStudentProfileInfo(int studentId) async {
    try {
      final response = await apiClient.get('/students/$studentId/profile-info');

      if (response.statusCode == 200) {
        return response.data['student'];
      } else {
        throw Exception('Failed to get student profile');
      }
    } catch (e) {
      throw Exception('Error getting student profile: $e');
    }
  }

  Future<void> updateStudentProfile({
    required int studentId,
    String? phone,
    String? email,
    String? profilePicture,
  }) async {
    try {
      final response = await apiClient.put(
        '/students/$studentId/update-profile',
        data: {
          'student_id': studentId,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (profilePicture != null) 'profile_picture': profilePicture,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<void> changePassword({
    required int studentId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '/students/$studentId/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        final error = response.data['error'] ?? 'Failed to change password';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }
}
