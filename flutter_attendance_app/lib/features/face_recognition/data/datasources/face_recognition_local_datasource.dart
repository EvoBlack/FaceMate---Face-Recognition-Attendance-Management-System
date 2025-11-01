import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/face_encoding_model.dart';
import '../../../../core/database/database_helper.dart';

abstract class FaceRecognitionLocalDataSource {
  Future<List<FaceEncodingModel>> getFaceEncodings();
  Future<int?> recognizeFace(Uint8List imageBytes);
  Future<void> saveFaceEncoding(FaceEncodingModel encoding);
}

class FaceRecognitionLocalDataSourceImpl implements FaceRecognitionLocalDataSource {
  final DatabaseHelper databaseHelper;

  FaceRecognitionLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<FaceEncodingModel>> getFaceEncodings() async {
    final encodings = await databaseHelper.getFaceEncodings();
    return encodings.map((e) => FaceEncodingModel.fromJson(e)).toList();
  }

  @override
  Future<int?> recognizeFace(Uint8List imageBytes) async {
    // Send image to backend for real face recognition
    try {
      developer.log('Sending face recognition request...', name: 'FaceRecognition');
      developer.log('Image size: ${imageBytes.length} bytes', name: 'FaceRecognition');
      
      final response = await http.post(
        Uri.parse('https://facemate-backend.onrender.com/api/face-recognition/recognize'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: imageBytes,
      );

      developer.log('Response status: ${response.statusCode}', name: 'FaceRecognition');
      developer.log('Response body: ${response.body}', name: 'FaceRecognition');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('✓ Face recognized: Student ID ${data['student_id']}', name: 'FaceRecognition');
        return data['student_id'];
      } else {
        developer.log('❌ Face recognition failed: ${response.body}', name: 'FaceRecognition');
        return null;
      }
    } catch (e) {
      developer.log('❌ Face recognition error: $e', name: 'FaceRecognition');
      return null;
    }
  }

  @override
  Future<void> saveFaceEncoding(FaceEncodingModel encoding) async {
    await databaseHelper.insertFaceEncoding(encoding.toJson());
  }
}