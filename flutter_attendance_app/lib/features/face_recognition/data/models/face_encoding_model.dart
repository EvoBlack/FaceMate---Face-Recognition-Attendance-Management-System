import 'dart:convert';
import '../../domain/entities/face_encoding.dart';

class FaceEncodingModel extends FaceEncoding {
  const FaceEncodingModel({
    required super.studentId,
    required super.encoding,
    required super.createdAt,
  });

  factory FaceEncodingModel.fromJson(Map<String, dynamic> json) {
    return FaceEncodingModel(
      studentId: json['student_id'],
      encoding: List<double>.from(json['encoding'] is String 
          ? jsonDecode(json['encoding']) 
          : json['encoding']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'encoding': jsonEncode(encoding),
      'created_at': createdAt.toIso8601String(),
    };
  }
}