import 'package:equatable/equatable.dart';

class FaceEncoding extends Equatable {
  final int studentId;
  final List<double> encoding;
  final DateTime createdAt;

  const FaceEncoding({
    required this.studentId,
    required this.encoding,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [studentId, encoding, createdAt];
}