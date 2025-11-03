import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/home_menu_card.dart';
import '../../../student_profile/presentation/pages/student_search_page.dart';
import 'teacher_management_page.dart';
import 'student_management_page.dart';
import 'password_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Management',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.2,
              children: [
                HomeMenuCard(
                  title: 'Teacher Management',
                  subtitle: 'Manage Teachers',
                  icon: Icons.school,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherManagementPage(),
                      ),
                    );
                  },
                ),
                HomeMenuCard(
                  title: 'Student Management',
                  subtitle: 'Manage Students',
                  icon: Icons.people,
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentManagementPage(),
                      ),
                    );
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
                HomeMenuCard(
                  title: 'Password Management',
                  subtitle: 'Reset Passwords',
                  icon: Icons.lock_reset,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}