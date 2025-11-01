import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/datasources/face_training_remote_datasource.dart';

class FaceTrainingPage extends StatefulWidget {
  final Map<String, dynamic>? student; // Optional: if provided, auto-select this student
  
  const FaceTrainingPage({super.key, this.student});

  @override
  State<FaceTrainingPage> createState() => _FaceTrainingPageState();
}

class _FaceTrainingPageState extends State<FaceTrainingPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  bool _isTraining = false;
  bool _isLoadingStudents = true;
  int _selectedCameraIndex = 0;
  late FaceTrainingRemoteDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = FaceTrainingRemoteDataSourceImpl(getIt.get());
    _initializeCamera();
    
    // If student is provided (from student home page), auto-select them
    if (widget.student != null) {
      _selectedStudent = widget.student;
      _isLoadingStudents = false;
    } else {
      // Otherwise load all students (for admin/teacher use)
      _loadStudents();
    }
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

  Future<void> _loadStudents() async {
    try {
      final students = await _dataSource.getStudents();
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

  Future<void> _trainFace() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    setState(() {
      _isTraining = true;
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();
      
      // Convert to base64
      final base64Image = base64Encode(imageBytes);
      
      // Send to backend for training
      final result = await _dataSource.trainFace(
        _selectedStudent!['id'],
        base64Image,
      );

      if (mounted) {
        // Check if this is a duplicate face error
        if (result.containsKey('duplicate_detected') && result['duplicate_detected'] == true) {
          // Show detailed error dialog for duplicate face
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error),
                  SizedBox(width: 8.w),
                  const Text('Duplicate Face Detected'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This face is already registered to:',
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['duplicate_student'] ?? 'Unknown',
                          style: AppTextStyles.h3.copyWith(color: AppColors.error),
                        ),
                        Text(
                          'Roll No: ${result['duplicate_roll_no'] ?? 'Unknown'}',
                          style: AppTextStyles.body2,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Similarity: ${((result['similarity'] ?? 0) * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Proxy attendance is not allowed. Each student must register their own face.',
                    style: AppTextStyles.body2.copyWith(color: AppColors.error),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Face trained successfully'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh students list to update training status
          _loadStudents();
          setState(() {
            _selectedStudent = null;
          });
          
          // Return success to parent page
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Training failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isTraining = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Training'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Student Selection (only show dropdown if no student provided)
            if (widget.student == null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Select Student for Face Training',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (_isLoadingStudents)
                    const Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _selectedStudent,
                        decoration: const InputDecoration(
                          labelText: 'Student',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: _students.map((student) {
                          final hasFaceEncoding = student['has_face_encoding'] == 1;
                          return DropdownMenuItem(
                            value: student,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${student['name']} (${student['roll_no']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasFaceEncoding)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 16.w,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (student) {
                          setState(() {
                            _selectedStudent = student;
                          });
                        },
                      ),
                    ),
                  if (_selectedStudent != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: _selectedStudent!['has_face_encoding'] == 1 
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedStudent!['has_face_encoding'] == 1 
                                ? Icons.check_circle 
                                : Icons.warning,
                            color: _selectedStudent!['has_face_encoding'] == 1 
                                ? AppColors.success 
                                : AppColors.warning,
                            size: 16.w,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _selectedStudent!['has_face_encoding'] == 1 
                                  ? 'Face already trained - will update existing'
                                  : 'No face data - will create new training',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _selectedStudent!['has_face_encoding'] == 1 
                                    ? AppColors.success 
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ],
                ),
              )
            else
              // Show selected student info (when auto-selected from student home)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 24.w),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStudent!['name'],
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Roll No: ${_selectedStudent!['roll_no']}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Training your face for attendance',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Camera Preview
            Expanded(
            child: _cameraController?.value.isInitialized == true
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CameraPreview(_cameraController!),
                      ),
                      
                      // Face Detection Overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: FaceTrainingOverlayPainter(),
                        ),
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
                      
                      // Instructions
                      Positioned(
                        top: 16.h,
                        left: 16.w,
                        right: 80.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Position face in the center frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                    ),
            ),
            
            // Train Button
            Container(
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTraining ? null : _trainFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: _isTraining
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Train Face',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceTrainingOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw face detection frame
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.height * 0.4,
    );

    // Draw rounded rectangle
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, paint);

    // Draw corner indicators
    const cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}