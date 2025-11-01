import '../models/attendance_record_model.dart';
import '../../../../core/network/api_client.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceRecordModel>> getAttendanceRecords({
    String? subject,
    DateTime? date,
  });
  
  Future<void> markAttendance({
    required int studentId,
    required String subject,
    required String status,
  });
  
  Future<Map<String, dynamic>> getAttendanceStats({
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords({
    String? subject,
    DateTime? date,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (subject != null) queryParams['subject'] = subject;
    if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];

    final response = await apiClient.get('/attendance', queryParameters: queryParams);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['records'] ?? response.data;
      return data.map((json) => AttendanceRecordModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch attendance records');
    }
  }

  @override
  Future<void> markAttendance({
    required int studentId,
    required String subject,
    required String status,
  }) async {
    final response = await apiClient.post('/attendance/mark', data: {
      'student_id': studentId,
      'subject': subject,
      'status': status,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to mark attendance');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats({
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (subject != null) queryParams['subject'] = subject;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await apiClient.get('/attendance/stats', queryParameters: queryParams);
    
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to fetch attendance statistics');
    }
  }
}