import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../student_profile/data/models/student_profile_model.dart';

class SubjectAttendanceDetailPage extends StatefulWidget {
  final int studentId;
  final SubjectAttendanceModel subject;

  const SubjectAttendanceDetailPage({
    super.key,
    required this.studentId,
    required this.subject,
  });

  @override
  State<SubjectAttendanceDetailPage> createState() => _SubjectAttendanceDetailPageState();
}

class _SubjectAttendanceDetailPageState extends State<SubjectAttendanceDetailPage> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _loadSubjectAttendance();
  }

  Future<void> _loadSubjectAttendance() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiClient.get(
        '/attendance',
        queryParameters: {
          'student_id': widget.studentId,
          'subject': widget.subject.subjectName,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _attendanceRecords = List<Map<String, dynamic>>.from(response.data['records']);
          _isLoading = false;
        });
      }
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
    final percentage = widget.subject.attendancePercentage;
    final color = _getPercentageColor(percentage);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.subjectName),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildSubjectHeader(color),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSubjectAttendance,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            return _buildAttendanceCard(_attendanceRecords[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeader(Color color) {
    final percentage = widget.subject.attendancePercentage;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.subject.subjectCode != null)
            Text(
              'Code: ${widget.subject.subjectCode}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14.sp,
              ),
            ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Attendance', '${percentage.toStringAsFixed(1)}%', Icons.percent),
              Container(
                width: 1,
                height: 50.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildHeaderStat('Present', widget.subject.presentCount.toString(), Icons.check_circle),
              Container(
                width: 1,
                height: 50.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildHeaderStat('Absent', widget.subject.absentCount.toString(), Icons.cancel),
              Container(
                width: 1,
                height: 50.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildHeaderStat('Total', widget.subject.totalClasses.toString(), Icons.class_),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final isPresent = record['status'] == 'Present';
    final date = DateTime.parse(record['date']);
    final formattedDate = DateFormat('EEEE, MMM dd, yyyy').format(date);
    final time = record['time'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border(
            left: BorderSide(
              color: isPresent ? Colors.green : Colors.red,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent ? Colors.green : Colors.red,
              size: 28.sp,
            ),
          ),
          title: Text(
            formattedDate,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    time,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (record['session_name'] != null) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.event, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        record['session_name'],
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (record['marked_by_teacher'] != null) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.person, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text(
                      'By: ${record['marked_by_teacher']}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              record['status'],
              style: TextStyle(
                color: isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No Attendance Records',
              style: AppTextStyles.h3.copyWith(color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              'No attendance has been marked for this subject yet',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
