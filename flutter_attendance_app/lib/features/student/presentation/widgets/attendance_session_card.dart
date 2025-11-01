import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';

class AttendanceSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final double distance;
  final VoidCallback onMarkAttendance;
  final Position? currentPosition;

  const AttendanceSessionCard({
    super.key,
    required this.session,
    required this.distance,
    required this.onMarkAttendance,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final isAlreadyMarked = session['already_marked'] == 1;
    // Add GPS tolerance of 40m to account for GPS accuracy
    const gpsTolerance = 40;
    final effectiveRadius = session['radius_meters'] + gpsTolerance;
    final isWithinRange = distance <= effectiveRadius;
    final canMarkAttendance = !isAlreadyMarked && isWithinRange && currentPosition != null;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isAlreadyMarked) {
      statusColor = AppColors.success;
      statusText = 'Attendance Marked';
      statusIcon = Icons.check_circle;
    } else if (!isWithinRange) {
      statusColor = AppColors.error;
      statusText = 'Too Far (${distance.toInt()}m)';
      statusIcon = Icons.location_off;
    } else if (currentPosition == null) {
      statusColor = AppColors.warning;
      statusText = 'Location Required';
      statusIcon = Icons.location_searching;
    } else {
      statusColor = AppColors.primary;
      statusText = 'Ready to Mark';
      statusIcon = Icons.location_on;
    }

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
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['subject_name'],
                        style: AppTextStyles.h3.copyWith(color: statusColor),
                      ),
                      Text(
                        statusText,
                        style: AppTextStyles.caption.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
                if (canMarkAttendance)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Available',
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

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Session Info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session: ${session['session_name']}',
                            style: AppTextStyles.body1,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Teacher: ${session['teacher_name']}',
                            style: AppTextStyles.body2,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Started: ${_formatTime(session['start_time'])}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Location Info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16.w,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Distance from class: ${distance.toInt()}m',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.radio_button_unchecked,
                            size: 16.w,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Required: ${session['radius_meters']}m (±40m GPS tolerance)',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canMarkAttendance ? onMarkAttendance : null,
                    icon: Icon(
                      isAlreadyMarked ? Icons.check : Icons.face,
                      size: 20.w,
                    ),
                    label: Text(
                      isAlreadyMarked 
                          ? 'Attendance Marked'
                          : canMarkAttendance 
                              ? 'Mark Attendance with Face'
                              : 'Cannot Mark Attendance',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAlreadyMarked 
                          ? AppColors.success 
                          : canMarkAttendance 
                              ? AppColors.primary 
                              : AppColors.textSecondary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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