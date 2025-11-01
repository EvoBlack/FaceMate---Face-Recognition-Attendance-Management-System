import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../database/database_helper.dart';
import 'connection_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance_records_usecase.dart';
import '../../features/attendance/domain/usecases/mark_attendance_usecase.dart';
import '../../features/face_recognition/data/datasources/face_recognition_local_datasource.dart';
import '../../features/face_recognition/data/repositories/face_recognition_repository_impl.dart';
import '../../features/face_recognition/domain/repositories/face_recognition_repository.dart';
import '../../features/face_recognition/domain/usecases/recognize_face_usecase.dart';
import '../../features/face_training/data/datasources/face_training_remote_datasource.dart';

// Simple service locator without external dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not found');
    }
    return service as T;
  }

  void register<T>(T service) {
    _services[T] = service;
  }
}

final getIt = ServiceLocator();

Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.register<SharedPreferences>(sharedPreferences);
  
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    sendTimeout: AppConfig.connectTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) {
      return status != null && status < 500;
    },
  ));
  getIt.register<Dio>(dio);
  
  // Core services
  getIt.register<ApiClient>(ApiClient(getIt.get<Dio>()));
  getIt.register<DatabaseHelper>(DatabaseHelper());
  getIt.register<ConnectionService>(ConnectionService(getIt.get<ApiClient>()));
  
  // Data sources
  getIt.register<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt.get<ApiClient>()),
  );
  getIt.register<AttendanceRemoteDataSource>(
    AttendanceRemoteDataSourceImpl(getIt.get<ApiClient>()),
  );
  getIt.register<FaceRecognitionLocalDataSource>(
    FaceRecognitionLocalDataSourceImpl(getIt.get<DatabaseHelper>()),
  );
  getIt.register<FaceTrainingRemoteDataSource>(
    FaceTrainingRemoteDataSourceImpl(getIt.get<ApiClient>()),
  );
  
  // Repositories
  getIt.register<AuthRepository>(
    AuthRepositoryImpl(getIt.get<AuthRemoteDataSource>()),
  );
  getIt.register<AttendanceRepository>(
    AttendanceRepositoryImpl(getIt.get<AttendanceRemoteDataSource>()),
  );
  getIt.register<FaceRecognitionRepository>(
    FaceRecognitionRepositoryImpl(getIt.get<FaceRecognitionLocalDataSource>()),
  );
  
  // Use cases
  getIt.register<LoginUseCase>(LoginUseCase(getIt.get<AuthRepository>()));
  getIt.register<GetAttendanceRecordsUseCase>(GetAttendanceRecordsUseCase(getIt.get<AttendanceRepository>()));
  getIt.register<MarkAttendanceUseCase>(MarkAttendanceUseCase(getIt.get<AttendanceRepository>()));
  getIt.register<RecognizeFaceUseCase>(RecognizeFaceUseCase(getIt.get<FaceRecognitionRepository>()));
  
  // Blocs - these will be created fresh each time
}