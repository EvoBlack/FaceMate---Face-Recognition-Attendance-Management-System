import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../student_profile/data/datasources/student_profile_remote_datasource.dart';
import '../../../student_profile/data/models/student_profile_model.dart';
import 'subject_attendance_detail_page.dart';

class StudentAttendanceOverviewPage extends StatefulWidget {
  final int studentId;

  const StudentAttendanceOverviewPage({super.key, required this.studentId});

  @override
  State<StudentAttendanceOverviewPage> createState() => _StudentAttendanceOverviewPageState();
}

class _StudentAttendanceOverviewPageState extends State<StudentAttendanceOverviewPage> {
  late final StudentProfileRemoteDatasource _datasource;
  StudentProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _datasource = StudentProfileRemoteDatasource(apiClient: getIt.get<ApiClient>());
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _datasource.getStudentProfile(widget.studentId);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load attendance data'))
              : RefreshIndicator(
                  onRefresh: _loadAttendanceData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverallAttendanceCard(),
                        SizedBox(height: 24.h),
                        Text(
                          'Subject-wise Attendance',
                          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12.h),
                        if (_profile!.subjects.isEmpty)
                          _buildEmptyState()
                        else
                          ..._profile!.subjects.map((subject) => _buildSubjectCard(subject)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverallAttendanceCard() {
    final stats = _profile!.overallStats;
    final percentage = stats.overallPercentage;
    final color = _getPercentageColor(percentage);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Attendance',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160.w,
                height: 160.w,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${stats.presentCount}/${stats.totalClasses}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Total', stats.totalClasses.toString(), Icons.class_),
              _buildStatChip('Present', stats.presentCount.toString(), Icons.check_circle),
              _buildStatChip('Absent', (stats.totalClasses - stats.presentCount).toString(), Icons.cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectAttendanceModel subject) {
    final percentage = subject.attendancePercentage;
    final color = _getPercentageColor(percentage);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectAttendanceDetailPage(
                studentId: widget.studentId,
                subject: subject,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${subject.presentCount}/${subject.totalClasses}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: color,
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
                      subject.subjectName,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subject.subjectCode != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Code: ${subject.subjectCode}',
                        style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildMiniStat(Icons.check_circle, subject.presentCount.toString(), Colors.green),
                        SizedBox(width: 12.w),
                        _buildMiniStat(Icons.cancel, subject.absentCount.toString(), Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Subjects Found',
            style: AppTextStyles.h3.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            'You have not been marked present in any subject yet',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
