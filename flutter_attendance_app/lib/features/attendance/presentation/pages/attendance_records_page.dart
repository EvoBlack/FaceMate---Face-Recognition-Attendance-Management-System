import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../widgets/attendance_filters.dart';
import '../widgets/attendance_thumbnail_widget.dart';

class AttendanceRecordsPage extends StatefulWidget {
  const AttendanceRecordsPage({super.key});

  @override
  State<AttendanceRecordsPage> createState() => _AttendanceRecordsPageState();
}

class _AttendanceRecordsPageState extends State<AttendanceRecordsPage> with WidgetsBindingObserver {
  String? _selectedSubject;
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _attendanceTableSessions = [];
  bool _isLoading = true;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    WidgetsBinding.instance.addObserver(this);
    _checkUserAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes back to foreground
      _loadData();
    }
  }

  void _checkUserAccess() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.role == 'student') {
        // Students should not access attendance records
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Only teachers and admins can view attendance records.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load attendance records and active sessions
      await Future.wait([
        _loadActiveSessions(),
        _loadAttendanceTableSessions(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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



  Future<void> _loadActiveSessions() async {
    try {
      final response = await _apiClient.get('/attendance/sessions/active');

      if (response.statusCode == 200) {
        setState(() {
          _activeSessions = List<Map<String, dynamic>>.from(response.data['active_sessions']);
        });
      }
    } catch (e) {
      developer.log('Error loading active sessions: $e', name: 'AttendanceRecords');
    }
  }

  Future<void> _loadAttendanceTableSessions() async {
    try {
      final response = await _apiClient.get('/attendance/records/table', queryParameters: {
        if (_selectedSubject != null) 'subject': _selectedSubject,
        if (_selectedDate != null) 'date': _selectedDate!.toIso8601String().split('T')[0],
      });

      if (response.statusCode == 200) {
        setState(() {
          _attendanceTableSessions = List<Map<String, dynamic>>.from(response.data['sessions']);
        });
      }
    } catch (e) {
      developer.log('Error loading attendance table sessions: $e', name: 'AttendanceRecords');
    }
  }

  void _onFiltersChanged({String? subject, DateTime? date}) {
    setState(() {
      _selectedSubject = (subject == 'All Subjects') ? null : subject;
      _selectedDate = date;
    });
    _loadAttendanceTableSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      color: AppColors.surface,
                      child: const TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Active Sessions', icon: Icon(Icons.location_on)),
                          Tab(text: 'Attendance Records', icon: Icon(Icons.history)),
                        ],
                      ),
                    ),
                    
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildActiveSessionsTab(),
                          _buildAttendanceRecordsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveSessionsTab() {
    if (_activeSessions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No Active Sessions',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 8.h),
                Text(
                  'No teachers have started attendance sessions yet',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _activeSessions.length,
      itemBuilder: (context, index) {
        final session = _activeSessions[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
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
            children: [
              // Session Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.success),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['subject_name'],
                            style: AppTextStyles.h3.copyWith(color: AppColors.success),
                          ),
                          Text(
                            session['session_name'],
                            style: AppTextStyles.body2,
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
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Session Details
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16.w, color: AppColors.textSecondary),
                        SizedBox(width: 8.w),
                        Text('Teacher: ${session['teacher_name']}', style: AppTextStyles.body2),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16.w, color: AppColors.textSecondary),
                        SizedBox(width: 8.w),
                        Text('Started: ${_formatTime(session['start_time'])}', style: AppTextStyles.body2),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16.w, color: AppColors.textSecondary),
                        SizedBox(width: 8.w),
                        Text('${session['attendance_count']} students marked attendance', style: AppTextStyles.body2),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecordsTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(16.w),
          color: AppColors.surface,
          child: AttendanceFilters(
            selectedSubject: _selectedSubject,
            selectedDate: _selectedDate,
            onFiltersChanged: _onFiltersChanged,
          ),
        ),
        
        // Records List
        Expanded(
          child: _attendanceTableSessions.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Sessions Found',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'No attendance sessions match your filters',
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  itemCount: _attendanceTableSessions.length,
                  itemBuilder: (context, index) {
                    final session = _attendanceTableSessions[index];
                    return AttendanceThumbnailWidget(session: session);
                  },
                ),
        ),
      ],
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}