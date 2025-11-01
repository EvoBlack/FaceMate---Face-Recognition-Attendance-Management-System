import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceRecordsUseCase {
  final AttendanceRepository repository;

  GetAttendanceRecordsUseCase(this.repository);

  Future<List<AttendanceRecord>> call({
    String? subject,
    DateTime? date,
  }) {
    return repository.getAttendanceRecords(
      subject: subject,
      date: date,
    );
  }
}