import 'dart:typed_data';
import '../repositories/face_recognition_repository.dart';

class RecognizeFaceUseCase {
  final FaceRecognitionRepository repository;

  RecognizeFaceUseCase(this.repository);

  Future<int?> call(Uint8List imageBytes) {
    return repository.recognizeFace(imageBytes);
  }
}