import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';

class AttendanceThumbnailWidget extends StatefulWidget {
  final Map<String, dynamic> session;

  const AttendanceThumbnailWidget({
    super.key,
    required this.session,
  });

  @override
  State<AttendanceThumbnailWidget> createState() => _AttendanceThumbnailWidgetState();
}

class _AttendanceThumbnailWidgetState extends State<AttendanceThumbnailWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final students = List<Map<String, dynamic>>.from(widget.session['students'] ?? []);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: _isExpanded 
                    ? BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r),
                      )
                    : BorderRadius.circular(12.r),
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
                              widget.session['session_name'] ?? 'Unknown Session',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${widget.session['subject_name']} - ${widget.session['teacher_name']}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Date: ${widget.session['session_date']}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: widget.session['is_active'] == 1 ? AppColors.success : AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              widget.session['is_active'] == 1 ? 'ACTIVE' : 'ENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.primary,
                            size: 24.w,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // Statistics Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatChip('Total', widget.session['total_students'], AppColors.primary),
                        SizedBox(width: 8.w),
                        _buildStatChip('Present', widget.session['present_count'], AppColors.success),
                        SizedBox(width: 8.w),
                        _buildStatChip('Absent', widget.session['absent_count'], AppColors.error),
                        if (widget.session['late_count'] > 0) ...[
                          SizedBox(width: 8.w),
                          _buildStatChip('Late', widget.session['late_count'], AppColors.warning),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Students Table
          if (_isExpanded) ...[
            if (students.isNotEmpty) ...[
              Container(
                constraints: BoxConstraints(maxHeight: 400.h),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        color: AppColors.surface,
                        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('Roll', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Name', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Course', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Status', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Time', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      // Table Rows
                      ...students.map<Widget>((student) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.surface)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  student['roll_no'] ?? '',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  student['student_name'] ?? '',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  student['course'] ?? '',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: _buildStatusChip(student['status'] ?? 'Absent'),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  _formatTime(student['attendance_time']),
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.all(32.w),
                child: Center(
                  child: Text(
                    'No students found for this session',
                    style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'present':
        color = AppColors.success;
        break;
      case 'absent':
        color = AppColors.error;
        break;
      case 'late':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '-';
    
    try {
      // Handle time format like "14:30:25"
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeString;
    } catch (e) {
      return '-';
    }
  }
}