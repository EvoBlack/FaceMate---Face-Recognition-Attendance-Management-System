import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String name;
  final String email;
  final String role;
  final List<String> subjects;
  
  // Student-specific properties
  final String? rollNo;
  final String? course;
  final String? year;
  final String? division;
  final String? subdivision;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.subjects,
    this.rollNo,
    this.course,
    this.year,
    this.division,
    this.subdivision,
  });

  // Helper method to convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'subjects': subjects,
      'roll_no': rollNo,
      'course': course,
      'year': year,
      'division': division,
      'subdivision': subdivision,
    };
  }

  @override
  List<Object?> get props => [id, username, name, email, role, subjects, rollNo, course, year, division, subdivision];
}