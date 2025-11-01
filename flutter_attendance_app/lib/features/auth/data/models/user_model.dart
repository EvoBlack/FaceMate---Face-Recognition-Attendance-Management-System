import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.name,
    required super.email,
    required super.role,
    required super.subjects,
    super.rollNo,
    super.course,
    super.year,
    super.division,
    super.subdivision,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['teacher_id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'teacher',
      subjects: List<String>.from(json['subjects'] ?? []),
      rollNo: json['roll_no'],
      course: json['course'],
      year: json['year']?.toString(),
      division: json['division'],
      subdivision: json['subdivision'],
    );
  }

  Map<String, dynamic> toJson() {
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
}