import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/attendance/domain/usecases/get_attendance_records_usecase.dart';
import 'features/attendance/domain/usecases/mark_attendance_usecase.dart';
import 'features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'features/face_recognition/domain/usecases/recognize_face_usecase.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/student/presentation/pages/student_home_page.dart';
import 'core/widgets/connection_status_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await setupServiceLocator();
  
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthBloc(getIt.get<LoginUseCase>())),
            BlocProvider(create: (_) => AttendanceBloc(
              getIt.get<GetAttendanceRecordsUseCase>(),
              getIt.get<MarkAttendanceUseCase>(),
            )),
            BlocProvider(create: (_) => FaceRecognitionBloc(getIt.get<RecognizeFaceUseCase>())),
          ],
          child: MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: ConnectionStatusWidget(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    // Check user role and navigate accordingly
                    if (state.user.role == 'student') {
                      return StudentHomePage(student: state.user.toMap());
                    } else {
                      return const HomePage();
                    }
                  }
                  return const LoginPage();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}