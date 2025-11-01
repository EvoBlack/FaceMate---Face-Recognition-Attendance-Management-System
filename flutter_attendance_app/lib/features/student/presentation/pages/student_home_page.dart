import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/attendance_session_card.dart';
import '../../../face_recognition/presentation/pages/face_recognition_page.dart';
import '../../../face_training/presentation/pages/face_training_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../student_profile/data/datasources/student_profile_remote_datasource.dart';
import '../../../student_profile/data/models/student_profile_model.dart';
import 'student_profile_edit_page.dart';
import 'change_password_page.dart';
import 'student_attendance_overview_page.dart';

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({super.key, required this.student});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  List<Map<String, dynamic>> _availableSessions = [];
  bool _isLoading = true;
  Position? _currentPosition;
  late ApiClient _apiClient;
  late StudentProfileRemoteDatasource _datasource;
  StudentProfileModel? _attendanceProfile;
  bool _isLoadingAttendance = true;
  bool _hasFaceTrained = false;
  bool _isCheckingFaceStatus = true;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _datasource = StudentProfileRemoteDatasource(apiClient: getIt.get<ApiClient>());
    _loadAvailableSessions();
    _getCurrentLocation();
    _loadAttendanceOverview();
    _checkFaceTrainingStatus();
  }

  Future<void> _loadAttendanceOverview() async {
    try {
      final profile = await _datasource.getStudentProfile(widget.student['id']);
      setState(() {
        _attendanceProfile = profile;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttendance = false);
      developer.log('Error loading attendance overview: $e', name: 'StudentHomePage');
    }
  }

  Future<void> _checkFaceTrainingStatus() async {
    try {
      final response = await _apiClient.get('/students/${widget.student['id']}');
      
      if (response.statusCode == 200) {
        final studentData = response.data['student'];
        setState(() {
          _hasFaceTrained = studentData['has_face_encoding'] == 1;
          _isCheckingFaceStatus = false;
        });
        developer.log('Face training status: $_hasFaceTrained', name: 'StudentHomePage');
      }
    } catch (e) {
      setState(() => _isCheckingFaceStatus = false);
      developer.log('Error checking face training status: $e', name: 'StudentHomePage');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      var permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for attendance'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current position with high accuracy for better location precision
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
      
      developer.log('Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude} (accuracy: ${_currentPosition!.accuracy}m)', name: 'StudentHomePage');
      
      setState(() {});
    } catch (e) {
      developer.log('Error getting location: $e', name: 'StudentHomePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableSessions() async {
    try {
      final response = await _apiClient.get('/attendance/sessions/student/${widget.student['id']}');
      
      if (response.statusCode == 200) {
        setState(() {
          _availableSessions = List<Map<String, dynamic>>.from(response.data['available_sessions']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAttendanceWithFaceRecognition(Map<String, dynamic> session) async {
    // Check if student has trained their face
    try {
      final response = await _apiClient.get('/students/${widget.student['id']}');
      
      if (response.statusCode == 200) {
        final studentData = response.data['student'];
        final hasFaceEncoding = studentData['has_face_encoding'] == 1;
        
        if (!hasFaceEncoding) {
          // Student hasn't trained their face
          if (mounted) {
            final shouldTrain = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Face Not Trained'),
                content: const Text(
                  'You need to train your face before marking attendance. '
                  'Would you like to go to Face Training now?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Train Face'),
                  ),
                ],
              ),
            );
            
            if (shouldTrain == true && mounted) {
              // Navigate to face training with student data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceTrainingPage(
                    student: widget.student, // Pass logged-in student data
                  ),
                ),
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      developer.log('Error checking face training status: $e', name: 'StudentHomePage');
    }
    
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    // Navigate to face recognition page with session context
    if (!mounted) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceRecognitionPage(
          isStudentMode: true,
          sessionData: {
            'session_id': session['id'],
            'student_id': widget.student['id'],
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
          },
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh sessions after successful attendance
      _loadAvailableSessions();
    }
  }

  double _calculateDistance(dynamic sessionLat, dynamic sessionLon) {
    if (_currentPosition == null) return 0.0;
    
    try {
      final lat = sessionLat is String ? double.parse(sessionLat) : sessionLat.toDouble();
      final lon = sessionLon is String ? double.parse(sessionLon) : sessionLon.toDouble();
      
      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );
    } catch (e) {
      developer.log('Error calculating distance: $e', name: 'StudentHomePage');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.student['name']}'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableSessions,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProfileEditPage(student: widget.student),
                  ),
                );
              } else if (value == 'change_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(studentId: widget.student['id']),
                  ),
                );
              } else if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.warning),
                    SizedBox(width: 12),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableSessions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Information',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Roll No: ${widget.student['roll_no']}',
                      style: AppTextStyles.body1.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Course: ${widget.student['course']} - Year ${widget.student['year']}',
                      style: AppTextStyles.body2.copyWith(color: Colors.white70),
                    ),
                    Text(
                      'Division: ${widget.student['division']}${widget.student['subdivision'] ?? ''}',
                      style: AppTextStyles.body2.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Attendance Overview Card
              _buildAttendanceOverviewCard(),

              SizedBox(height: 24.h),

              // Location Status
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _currentPosition != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _currentPosition != null ? AppColors.success : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null ? Icons.location_on : Icons.location_off,
                      color: _currentPosition != null ? AppColors.success : AppColors.warning,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _currentPosition != null 
                            ? 'Location ready (±${_currentPosition!.accuracy.toInt()}m accuracy)'
                            : 'Location required for attendance marking',
                        style: TextStyle(
                          color: _currentPosition != null ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Available Sessions
              Text(
                'Available Attendance Sessions',
                style: AppTextStyles.h3,
              ),
              SizedBox(height: 16.h),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_availableSessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48.w,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No Active Sessions',
                        style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No teachers have started attendance sessions yet. Please check back later.',
                        style: AppTextStyles.body2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availableSessions.length,
                      itemBuilder: (context, index) {
                        final session = _availableSessions[index];
                        final distance = _calculateDistance(
                          session['latitude'],
                          session['longitude'],
                        );
                        
                        return AttendanceSessionCard(
                          session: session,
                          distance: distance,
                          onMarkAttendance: () => _markAttendanceWithFaceRecognition(session),
                          currentPosition: _currentPosition,
                        );
                      },
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: AppTextStyles.h3,
                    ),
                    SizedBox(height: 16.h),
                    
                    // Only show Face Training if not already trained
                    if (!_isCheckingFaceStatus && !_hasFaceTrained)
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceTrainingPage(
                                student: widget.student, // Pass logged-in student data
                              ),
                            ),
                          );
                          // Refresh face training status after returning
                          if (result == true) {
                            _checkFaceTrainingStatus();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.success, Color(0xFF45B649)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.face_6,
                                  size: 32.w,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Face Training Required',
                                      style: AppTextStyles.h3.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Train your face to mark attendance',
                                      style: AppTextStyles.body2.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20.w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Show face trained status if already trained
                    if (!_isCheckingFaceStatus && _hasFaceTrained)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.success, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.verified,
                                size: 32.w,
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Face Trained',
                                    style: AppTextStyles.h3.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Your face is registered for attendance',
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 24.w,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceOverviewCard() {
    if (_isLoadingAttendance) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_attendanceProfile == null) {
      return const SizedBox.shrink();
    }

    final stats = _attendanceProfile!.overallStats;
    final percentage = stats.overallPercentage;
    
    Color getPercentageColor() {
      if (percentage >= 75) return Colors.green;
      if (percentage >= 60) return Colors.orange;
      return Colors.red;
    }

    final color = getPercentageColor();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentAttendanceOverviewPage(studentId: widget.student['id']),
          ),
        ).then((_) => _loadAttendanceOverview());
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Attendance',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        '${stats.presentCount} Present',
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.class_, size: 16.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        '${stats.totalClasses} Total',
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward,
                        size: 14.sp,
                        color: Colors.white.withValues(alpha: 0.9),
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
