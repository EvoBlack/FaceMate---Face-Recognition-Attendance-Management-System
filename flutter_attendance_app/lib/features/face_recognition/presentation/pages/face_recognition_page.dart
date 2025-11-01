import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../bloc/face_recognition_bloc.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/subject_selector.dart';

class FaceRecognitionPage extends StatefulWidget {
  final bool isStudentMode;
  final Map<String, dynamic>? sessionData;

  const FaceRecognitionPage({
    super.key,
    this.isStudentMode = false,
    this.sessionData,
  });

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String? _selectedSubject;
  final Set<int> _markedStudents = {};
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;
    
    await _cameraController?.dispose();
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    
    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
    );
    
    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _startRecognition() {
    // In student mode, subject is not required (comes from session)
    if (!widget.isStudentMode && _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }
    
    context.read<FaceRecognitionBloc>().add(FaceRecognitionStarted());
  }

  void _stopRecognition() {
    context.read<FaceRecognitionBloc>().add(FaceRecognitionStopped());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: AppColors.primary,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<FaceRecognitionBloc, FaceRecognitionState>(
            listener: (context, state) async {
              if (state is FaceRecognitionSuccess) {
                if (!_markedStudents.contains(state.studentId)) {
                  _markedStudents.add(state.studentId);
                  
                  if (widget.isStudentMode && widget.sessionData != null) {
                    // Student mode: Call API directly to mark attendance
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    
                    try {
                      final apiClient = getIt.get<ApiClient>();
                      final response = await apiClient.post('/attendance/mark-student', data: {
                        'student_id': widget.sessionData!['student_id'],
                        'session_id': widget.sessionData!['session_id'],
                        'latitude': widget.sessionData!['latitude'],
                        'longitude': widget.sessionData!['longitude'],
                        'confidence': 0.95, // Default confidence for face recognition
                      });
                      
                      if (response.statusCode == 200) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Attendance marked successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          // Return success to student page
                          navigator.pop(true);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Error marking attendance'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  } else {
                    // Teacher mode: Use bloc
                    final messenger = ScaffoldMessenger.of(context);
                    context.read<AttendanceBloc>().add(
                      AttendanceMarked(
                        studentId: state.studentId,
                        subject: _selectedSubject!,
                      ),
                    );
                    
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Student ${state.studentId} recognized!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              } else if (state is FaceRecognitionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
          BlocListener<AttendanceBloc, AttendanceState>(
            listener: (context, state) {
              if (state is AttendanceMarkingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Attendance marked for ${state.studentName}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            // Subject Selector (only for teacher mode)
            if (!widget.isStudentMode)
              Container(
                padding: EdgeInsets.all(16.w),
                color: AppColors.surface,
                child: SubjectSelector(
                  onSubjectSelected: (subject) {
                    setState(() {
                      _selectedSubject = subject;
                      _markedStudents.clear();
                    });
                  },
                ),
              ),
            
            // Camera Preview
            Expanded(
              child: _cameraController?.value.isInitialized == true
                  ? Stack(
                      children: [
                        CameraPreviewWidget(
                          controller: _cameraController!,
                          onImageCaptured: (imageBytes) {
                            context.read<FaceRecognitionBloc>().add(
                              FaceRecognized(imageBytes: imageBytes),
                            );
                          },
                        ),
                        // Camera switch button
                        if (_cameras != null && _cameras!.length > 1)
                          Positioned(
                            top: 16.h,
                            right: 16.w,
                            child: FloatingActionButton(
                              mini: true,
                              onPressed: _switchCamera,
                              backgroundColor: Colors.white.withValues(alpha: 0.8),
                              child: const Icon(
                                Icons.flip_camera_ios,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            
            // Controls
            Container(
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  // Status
                  BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
                    builder: (context, state) {
                      String status = 'Ready';
                      Color statusColor = AppColors.textSecondary;
                      
                      if (state is FaceRecognitionActive) {
                        status = 'Scanning for faces...';
                        statusColor = AppColors.primary;
                      } else if (state is FaceRecognitionProcessing) {
                        status = 'Processing...';
                        statusColor = AppColors.warning;
                      } else if (state is FaceRecognitionSuccess) {
                        status = 'Face recognized!';
                        statusColor = AppColors.success;
                      } else if (state is FaceRecognitionNotFound) {
                        status = 'Face not recognized';
                        statusColor = AppColors.error;
                      }
                      
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.body2.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Attendance Count
                  Text(
                    'Students marked: ${_markedStudents.length}',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Control Buttons
                  Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
                          builder: (context, state) {
                            final isActive = state is FaceRecognitionActive ||
                                state is FaceRecognitionProcessing;
                            
                            return ElevatedButton(
                              onPressed: isActive ? _stopRecognition : _startRecognition,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive 
                                    ? AppColors.error 
                                    : AppColors.primary,
                              ),
                              child: Text(
                                isActive ? 'Stop Recognition' : 'Start Recognition',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}