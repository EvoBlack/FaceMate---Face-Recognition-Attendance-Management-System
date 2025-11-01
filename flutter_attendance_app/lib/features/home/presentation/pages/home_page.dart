import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../face_recognition/presentation/pages/face_recognition_page.dart';
import '../../../attendance/presentation/pages/attendance_records_page.dart';
import '../../../face_training/presentation/pages/face_training_page.dart';
import '../../../teacher/presentation/pages/session_management_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../student_profile/presentation/pages/student_search_page.dart';
import '../widgets/home_menu_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingActivity = true;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    try {
      final response = await _apiClient.get('/attendance/records/table');

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _recentActivity = List<Map<String, dynamic>>.from(response.data['sessions'] ?? []);
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActivity = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FaceMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          state.user.name,
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${state.user.role.toUpperCase()} • ${state.user.subjects.length} Subject(s)',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.h3,
                  ),
                  SizedBox(height: 16.h),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.2,
                    children: [
                      // Admin Dashboard - Only for admins
                      if (state.user.role == 'admin')
                        HomeMenuCard(
                          title: 'Admin Dashboard',
                          subtitle: 'Manage System',
                          icon: Icons.admin_panel_settings,
                          color: AppColors.error,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminDashboardPage(),
                              ),
                            );
                          },
                        ),
                      HomeMenuCard(
                        title: 'Face Recognition',
                        subtitle: 'Mark Attendance',
                        icon: Icons.face_retouching_natural,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaceRecognitionPage(),
                            ),
                          );
                        },
                      ),
                      HomeMenuCard(
                        title: 'Face Training',
                        subtitle: 'Train New Faces',
                        icon: Icons.face_6,
                        color: AppColors.success,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaceTrainingPage(),
                            ),
                          );
                        },
                      ),
                      HomeMenuCard(
                        title: 'Attendance Records',
                        subtitle: 'View History',
                        icon: Icons.history,
                        color: AppColors.accent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AttendanceRecordsPage(),
                            ),
                          );
                        },
                      ),
                      HomeMenuCard(
                        title: 'Attendance Sessions',
                        subtitle: 'Manage Sessions',
                        icon: Icons.location_on,
                        color: AppColors.warning,
                        onTap: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionManagementPage(teacher: authState.user.toMap()),
                              ),
                            );
                          }
                        },
                      ),
                      HomeMenuCard(
                        title: 'Student Profiles',
                        subtitle: 'Search & View',
                        icon: Icons.person_search,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentSearchPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: AppTextStyles.h3,
                      ),
                      if (!_isLoadingActivity)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _loadRecentActivity,
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  
                  Card(
                    child: _isLoadingActivity
                        ? Padding(
                            padding: EdgeInsets.all(32.w),
                            child: const Center(child: CircularProgressIndicator()),
                          )
                        : _recentActivity.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 48.w,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'No recent sessions',
                                        style: AppTextStyles.body2.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  children: _recentActivity.take(3).toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final session = entry.value;
                                    final isLast = index == _recentActivity.take(3).length - 1;
                                    final presentCount = session['present_count'] ?? 0;
                                    final absentCount = session['absent_count'] ?? 0;
                                    final totalCount = session['total_students'] ?? 0;
                                    
                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            child: const Icon(
                                              Icons.groups,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          title: Text(
                                            session['subject_name'] ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(Icons.check_circle, size: 14.w, color: AppColors.success),
                                              SizedBox(width: 4.w),
                                              Text('$presentCount', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                                              SizedBox(width: 12.w),
                                              Icon(Icons.cancel, size: 14.w, color: AppColors.error),
                                              SizedBox(width: 4.w),
                                              Text('$absentCount', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                                              SizedBox(width: 12.w),
                                              Text('of $totalCount', style: AppTextStyles.caption),
                                            ],
                                          ),
                                          trailing: Text(
                                            _formatDate(session['session_date']),
                                            style: AppTextStyles.caption,
                                          ),
                                        ),
                                        if (!isLast) const Divider(),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                  ),
                ],
              ),
            );
          }
          
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}