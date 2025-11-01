import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceRecords({
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