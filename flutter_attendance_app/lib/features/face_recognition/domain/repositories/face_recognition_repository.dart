import 'dart:typed_data';
import '../entities/face_encoding.dart';

abstract class FaceRecognitionRepository {
  Future<List<FaceEncoding>> getFaceEncodings();
  Future<int?> recognizeFace(Uint8List imageBytes);
  Future<void> saveFaceEncoding(FaceEncoding encoding);
}