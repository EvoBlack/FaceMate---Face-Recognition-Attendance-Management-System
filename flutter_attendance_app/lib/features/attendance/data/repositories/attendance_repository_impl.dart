import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords({
    String? subject,
    DateTime? date,
  }) async {
    return await remoteDataSource.getAttendanceRecords(
      subject: subject,
      date: date,
    );
  }

  @override
  Future<void> markAttendance({
    required int studentId,
    required String subject,
    required String status,
  }) async {
    await remoteDataSource.markAttendance(
      studentId: studentId,
      subject: subject,
      status: status,
    );
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats({
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await remoteDataSource.getAttendanceStats(
      subject: subject,
      startDate: startDate,
      endDate: endDate,
    );
  }
}