import '../../../../core/network/api_client.dart';
import '../models/student_profile_model.dart';

class StudentProfileRemoteDatasource {
  final ApiClient apiClient;

  StudentProfileRemoteDatasource({required this.apiClient});

  Future<List<StudentSearchModel>> searchStudents(String query) async {
    try {
      final response = await apiClient.get(
        '/students/search',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final List students = response.data['students'];
        return students.map((s) => StudentSearchModel.fromJson(s)).toList();
      } else {
        throw Exception('Failed to search students');
      }
    } catch (e) {
      throw Exception('Error searching students: $e');
    }
  }

  Future<StudentProfileModel> getStudentProfile(int studentId) async {
    try {
      final response = await apiClient.get('/students/$studentId/profile');

      if (response.statusCode == 200) {
        return StudentProfileModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get student profile');
      }
    } catch (e) {
      throw Exception('Error getting student profile: $e');
    }
  }
}
