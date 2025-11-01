import '../../../../core/network/api_client.dart';

abstract class FaceTrainingRemoteDataSource {
  Future<Map<String, dynamic>> trainFace(int studentId, String imageBase64);
  Future<List<Map<String, dynamic>>> getStudents();
  Future<Map<String, dynamic>> getStudentDetails(int studentId);
}

class FaceTrainingRemoteDataSourceImpl implements FaceTrainingRemoteDataSource {
  final ApiClient apiClient;

  FaceTrainingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> trainFace(int studentId, String imageBase64) async {
    final response = await apiClient.post('/face-recognition/train', data: {
      'student_id': studentId,
      'image_data': imageBase64,
    });

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(response.data['error'] ?? 'Face training failed');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudents() async {
    final response = await apiClient.get('/students');

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data['students']);
    } else {
      throw Exception('Failed to load students');
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentDetails(int studentId) async {
    final response = await apiClient.get('/students/$studentId');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load student details');
    }
  }
}