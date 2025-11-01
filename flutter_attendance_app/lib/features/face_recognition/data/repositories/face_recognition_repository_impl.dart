import 'dart:typed_data';
import '../../domain/entities/face_encoding.dart';
import '../../domain/repositories/face_recognition_repository.dart';
import '../datasources/face_recognition_local_datasource.dart';
import '../models/face_encoding_model.dart';

class FaceRecognitionRepositoryImpl implements FaceRecognitionRepository {
  final FaceRecognitionLocalDataSource localDataSource;

  FaceRecognitionRepositoryImpl(this.localDataSource);

  @override
  Future<List<FaceEncoding>> getFaceEncodings() async {
    return await localDataSource.getFaceEncodings();
  }

  @override
  Future<int?> recognizeFace(Uint8List imageBytes) async {
    return await localDataSource.recognizeFace(imageBytes);
  }

  @override
  Future<void> saveFaceEncoding(FaceEncoding encoding) async {
    final model = FaceEncodingModel(
      studentId: encoding.studentId,
      encoding: encoding.encoding,
      createdAt: encoding.createdAt,
    );
    await localDataSource.saveFaceEncoding(model);
  }
}