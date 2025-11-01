import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.status);
    final statusIcon = _getStatusIcon(record.status);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.studentName,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Roll No: ${record.rollNo}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    constraints: BoxConstraints(maxWidth: 80.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 10.w,
                          color: statusColor,
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            record.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Details
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildDetailItem(
                    icon: Icons.subject,
                    label: 'Subject',
                    value: record.subject,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormat('MMM dd, yyyy').format(record.date),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            _buildDetailItem(
              icon: Icons.access_time,
              label: 'Time',
              value: record.time,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.w,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}