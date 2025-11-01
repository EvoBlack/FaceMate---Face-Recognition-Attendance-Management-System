class StudentProfileModel {
  final int id;
  final String name;
  final String rollNo;
  final String course;
  final String year;
  final String division;
  final String? subdivision;
  final bool hasFaceEncoding;
  final String? faceEncodingDate;
  final List<SubjectAttendanceModel> subjects;
  final List<AttendanceRecordModel> recentAttendance;
  final OverallStatsModel overallStats;

  StudentProfileModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.course,
    required this.year,
    required this.division,
    this.subdivision,
    required this.hasFaceEncoding,
    this.faceEncodingDate,
    required this.subjects,
    required this.recentAttendance,
    required this.overallStats,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['student']['id'],
      name: json['student']['name'],
      rollNo: json['student']['roll_no'],
      course: json['student']['course'],
      year: json['student']['year'],
      division: json['student']['division'],
      subdivision: json['student']['subdivision'],
      hasFaceEncoding: json['student']['has_face_encoding'] == 1,
      faceEncodingDate: json['student']['face_encoding_date'],
      subjects: (json['subjects'] as List)
          .map((s) => SubjectAttendanceModel.fromJson(s))
          .toList(),
      recentAttendance: (json['recent_attendance'] as List)
          .map((r) => AttendanceRecordModel.fromJson(r))
          .toList(),
      overallStats: OverallStatsModel.fromJson(json['overall_stats']),
    );
  }
}

class SubjectAttendanceModel {
  final int subjectId;
  final String subjectName;
  final String? subjectCode;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;

  SubjectAttendanceModel({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
  });

  factory SubjectAttendanceModel.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceModel(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      subjectCode: json['subject_code'],
      totalClasses: json['total_classes'],
      presentCount: json['present_count'],
      absentCount: json['absent_count'],
      attendancePercentage: (json['attendance_percentage'] as num).toDouble(),
    );
  }
}

class AttendanceRecordModel {
  final String date;
  final String? time;
  final String status;
  final String subject;
  final String? subjectCode;
  final String? markedByTeacher;
  final double? recognitionConfidence;
  final String? sessionName;

  AttendanceRecordModel({
    required this.date,
    this.time,
    required this.status,
    required this.subject,
    this.subjectCode,
    this.markedByTeacher,
    this.recognitionConfidence,
    this.sessionName,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      date: json['date'],
      time: json['time'],
      status: json['status'],
      subject: json['subject'],
      subjectCode: json['subject_code'],
      markedByTeacher: json['marked_by_teacher'],
      recognitionConfidence: json['recognition_confidence']?.toDouble(),
      sessionName: json['session_name'],
    );
  }
}

class OverallStatsModel {
  final int totalClasses;
  final int presentCount;
  final double overallPercentage;

  OverallStatsModel({
    required this.totalClasses,
    required this.presentCount,
    required this.overallPercentage,
  });

  factory OverallStatsModel.fromJson(Map<String, dynamic> json) {
    return OverallStatsModel(
      totalClasses: json['total_classes'],
      presentCount: json['present_count'],
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
    );
  }
}

class StudentSearchModel {
  final int id;
  final String name;
  final String rollNo;
  final String course;
  final String year;
  final String division;
  final String? subdivision;
  final bool hasFaceEncoding;

  StudentSearchModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.course,
    required this.year,
    required this.division,
    this.subdivision,
    required this.hasFaceEncoding,
  });

  factory StudentSearchModel.fromJson(Map<String, dynamic> json) {
    return StudentSearchModel(
      id: json['id'],
      name: json['name'],
      rollNo: json['roll_no'],
      course: json['course'],
      year: json['year'],
      division: json['division'],
      subdivision: json['subdivision'],
      hasFaceEncoding: json['has_face_encoding'] == 1,
    );
  }
}
