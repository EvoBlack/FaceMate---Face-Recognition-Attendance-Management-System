import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 32.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40.r),
                        ),
                        child: Icon(
                          Icons.face,
                          size: 40.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'FaceMate',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Face Recognition Attendance System',
                          style: AppTextStyles.body2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Welcome Text
                Text(
                  'Welcome Back',
                  style: AppTextStyles.h2,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sign in to continue',
                  style: AppTextStyles.body2,
                ),
                
                SizedBox(height: 24.h),
                
                // Login Form
                const LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}