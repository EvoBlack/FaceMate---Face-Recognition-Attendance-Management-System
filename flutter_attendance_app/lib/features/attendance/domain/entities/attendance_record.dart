import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final int id;
  final int studentId;
  final String studentName;
  final String rollNo;
  final String subject;
  final DateTime date;
  final String time;
  final String status;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    required this.subject,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentName,
    rollNo,
    subject,
    date,
    time,
    status,
  ];
}