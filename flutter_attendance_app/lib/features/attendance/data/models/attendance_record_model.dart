import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.rollNo,
    required super.subject,
    required super.date,
    required super.time,
    required super.status,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'] ?? json['name'] ?? '',
      rollNo: json['roll_no'] ?? '',
      subject: json['subject'] ?? json['subject_name'] ?? '',
      date: DateTime.parse(json['attendance_date'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      time: json['attendance_time'] ?? json['time'] ?? '',
      status: json['status'] ?? 'Present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'roll_no': rollNo,
      'subject': subject,
      'attendance_date': date.toIso8601String().split('T')[0],
      'attendance_time': time,
      'status': status,
    };
  }
}