import '../repositories/attendance_repository.dart';

class MarkAttendanceUseCase {
  final AttendanceRepository repository;

  MarkAttendanceUseCase(this.repository);

  Future<void> call({
    required int studentId,
    required String subject,
    required String status,
  }) {
    return repository.markAttendance(
      studentId: studentId,
      subject: subject,
      status: status,
    );
  }
}