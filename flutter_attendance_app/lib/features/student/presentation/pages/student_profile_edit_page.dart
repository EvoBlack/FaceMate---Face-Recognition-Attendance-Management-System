import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/datasources/student_datasource.dart';

class StudentProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentProfileEditPage({super.key, required this.student});

  @override
  State<StudentProfileEditPage> createState() => _StudentProfileEditPageState();
}

class _StudentProfileEditPageState extends State<StudentProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  late final StudentDatasource _datasource;
  final _imagePicker = ImagePicker();
  
  String? _profilePictureBase64;
  File? _selectedImageFile;
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _datasource = StudentDatasource(apiClient: getIt.get<ApiClient>());
    _loadProfileInfo();
  }

  Future<void> _loadProfileInfo() async {
    try {
      final profile = await _datasource.getStudentProfileInfo(widget.student['id']);
      setState(() {
        _phoneController.text = profile['phone'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _profilePictureBase64 = profile['profile_picture'];
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = File(image.path);
          _profilePictureBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _datasource.updateStudentProfile(
        studentId: widget.student['id'],
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        profilePicture: _profilePictureBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
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

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfilePictureSection(),
                    SizedBox(height: 32.h),
                    _buildInfoCard(),
                    SizedBox(height: 24.h),
                    _buildContactCard(),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _selectedImageFile != null
                    ? FileImage(_selectedImageFile!)
                    : (_profilePictureBase64 != null && _profilePictureBase64!.isNotEmpty
                        ? MemoryImage(base64Decode(_profilePictureBase64!))
                        : null) as ImageProvider?,
                child: (_selectedImageFile == null && 
                       (_profilePictureBase64 == null || _profilePictureBase64!.isEmpty))
                    ? Text(
                        widget.student['name'][0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20.sp),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Tap to change profile picture',
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildReadOnlyField('Name', widget.student['name']),
            _buildReadOnlyField('Roll No', widget.student['roll_no']),
            _buildReadOnlyField('Course', widget.student['course']),
            _buildReadOnlyField('Year', widget.student['year']),
            _buildReadOnlyField('Division', widget.student['division']),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
