import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';

class SessionManagementPage extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const SessionManagementPage({super.key, required this.teacher});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  final _sessionNameController = TextEditingController();
  String? _selectedSubject;
  List<String> _subjects = [];
  List<Map<String, dynamic>> _activeSessions = [];
  Position? _currentPosition;
  bool _isLoading = false;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _subjects = List<String>.from(widget.teacher['subjects'] ?? []);
    if (_subjects.isNotEmpty) {
      _selectedSubject = _subjects.first;
    }
    _loadActiveSessions();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to start sessions'),
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
      
      developer.log('Teacher location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude} (accuracy: ${_currentPosition!.accuracy}m)', name: 'SessionManagement');
      
      setState(() {});
    } catch (e) {
      developer.log('Error getting location: $e', name: 'SessionManagement');
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

  Future<void> _loadActiveSessions() async {
    try {
      final response = await _apiClient.get('/attendance/sessions/active');
      
      if (response.statusCode == 200) {
        setState(() {
          _activeSessions = List<Map<String, dynamic>>.from(response.data['active_sessions']);
        });
      }
    } catch (e) {
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

  Future<void> _startSession() async {
    if (_selectedSubject == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject and ensure location is available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sessionName = _sessionNameController.text.trim().isEmpty
          ? 'Session ${DateTime.now().toString().substring(11, 16)}'
          : _sessionNameController.text.trim();

      final response = await _apiClient.post('/attendance/sessions', data: {
        'teacher_id': widget.teacher['id'],
        'subject': _selectedSubject,
        'session_name': sessionName,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'radius_meters': 20, // Classroom distance
        'gps_accuracy': _currentPosition!.accuracy, // Send GPS accuracy for tolerance
      });

      if (response.statusCode == 200) {
        _sessionNameController.clear();
        _loadActiveSessions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session started: $sessionName'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting session: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _endSession(int sessionId) async {
    try {
      final response = await _apiClient.post('/attendance/sessions/$sessionId/end');
      
      if (response.statusCode == 200) {
        _loadActiveSessions();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session ended successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending session: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Sessions'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start New Session Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Session',
                    style: AppTextStyles.h3,
                  ),
                  SizedBox(height: 16.h),

                  // Session Name
                  TextField(
                    controller: _sessionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Session Name (Optional)',
                      hintText: 'e.g., Morning Lecture, Lab Session',
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Subject Selection
                  if (_subjects.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.book),
                      ),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                    ),
                  SizedBox(height: 16.h),

                  // Location Status
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _currentPosition != null 
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
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
                                : 'Getting location...',
                            style: TextStyle(
                              color: _currentPosition != null ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startSession,
                      icon: _isLoading 
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isLoading ? 'Starting...' : 'Start Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Active Sessions
            Text(
              'Active Sessions',
              style: AppTextStyles.h3,
            ),
            SizedBox(height: 16.h),

            if (_activeSessions.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.r),
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
                    Text(
                      'Start a session to allow students to mark attendance',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeSessions.length,
                itemBuilder: (context, index) {
                  final session = _activeSessions[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session['subject_name'],
                                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                                  ),
                                  Text(
                                    session['session_name'],
                                    style: AppTextStyles.body1,
                                  ),
                                  Text(
                                    'Teacher: ${session['teacher_name']}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(Icons.people, size: 16.w, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              '${session['attendance_count']} students marked',
                              style: AppTextStyles.caption,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _endSession(session['id']),
                              icon: const Icon(Icons.stop, size: 16),
                              label: const Text('End Session'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}