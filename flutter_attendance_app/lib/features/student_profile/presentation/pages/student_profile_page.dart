import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/datasources/student_profile_remote_datasource.dart';
import '../../data/models/student_profile_model.dart';

class StudentProfilePage extends StatefulWidget {
  final int studentId;

  const StudentProfilePage({super.key, required this.studentId});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late final StudentProfileRemoteDatasource _datasource;
  StudentProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _datasource = StudentProfileRemoteDatasource(apiClient: getIt.get<ApiClient>());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentInfo(),
                        SizedBox(height: 24.h),
                        _buildOverallStats(),
                        SizedBox(height: 24.h),
                        _buildSubjectsSection(),
                        SizedBox(height: 24.h),
                        _buildRecentAttendance(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 40.r,
              child: Text(
                _profile!.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _profile!.name,
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Roll No: ${_profile!.rollNo}',
              style: AppTextStyles.h3.copyWith(color: Colors.grey[700]),
            ),
            SizedBox(height: 16.h),
            Divider(height: 1.h),
            SizedBox(height: 16.h),
            _buildInfoRow('Course', _profile!.course),
            _buildInfoRow('Year', _profile!.year),
            _buildInfoRow('Division', _profile!.division),
            if (_profile!.subdivision != null)
              _buildInfoRow('Subdivision', _profile!.subdivision!),
            _buildInfoRow(
              'Face Training',
              _profile!.hasFaceEncoding ? 'Completed' : 'Not Completed',
              valueColor: _profile!.hasFaceEncoding ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body1.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final stats = _profile!.overallStats;
    final percentage = stats.overallPercentage;
    
    Color getPercentageColor() {
      if (percentage >= 75) return Colors.green;
      if (percentage >= 60) return Colors.orange;
      return Colors.red;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Attendance',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Classes',
                  stats.totalClasses.toString(),
                  Icons.class_,
                  AppColors.primary,
                ),
                _buildStatItem(
                  'Present',
                  stats.presentCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Percentage',
                  '${percentage.toStringAsFixed(1)}%',
                  Icons.percent,
                  getPercentageColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection() {
    if (_profile!.subjects.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: Text(
              'No subjects enrolled',
              style: AppTextStyles.body1.copyWith(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject-wise Attendance',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        ...(_profile!.subjects.map((subject) => _buildSubjectCard(subject))),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectAttendanceModel subject) {
    final percentage = subject.attendancePercentage;
    
    Color getPercentageColor() {
      if (percentage >= 75) return Colors.green;
      if (percentage >= 60) return Colors.orange;
      return Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subject.subjectName,
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: getPercentageColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: getPercentageColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (subject.subjectCode != null) ...[
              SizedBox(height: 4.h),
              Text(
                'Code: ${subject.subjectCode}',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubjectStat('Total', subject.totalClasses.toString()),
                _buildSubjectStat('Present', subject.presentCount.toString(), Colors.green),
                _buildSubjectStat('Absent', subject.absentCount.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStat(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentAttendance() {
    if (_profile!.recentAttendance.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: Text(
              'No attendance records',
              style: AppTextStyles.body1.copyWith(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Attendance (Last 20)',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        ...(_profile!.recentAttendance.map((record) => _buildAttendanceCard(record))),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecordModel record) {
    final isPresent = record.status == 'Present';
    final date = DateTime.parse(record.date);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          record.subject,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$formattedDate ${record.time ?? ''}'),
            if (record.sessionName != null)
              Text('Session: ${record.sessionName}', style: TextStyle(fontSize: 12.sp)),
            if (record.markedByTeacher != null)
              Text('By: ${record.markedByTeacher}', style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            record.status,
            style: TextStyle(
              color: isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }
}
