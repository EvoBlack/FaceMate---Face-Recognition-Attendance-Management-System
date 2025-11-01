import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubject;
  bool _isLoading = true;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadTeachers(),
        _loadSubjects(),
      ]);
    } catch (e) {
      developer.log('Error loading data: $e', name: 'TeacherManagement');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await _apiClient.get('/teachers');
      if (response.statusCode == 200) {
        setState(() {
          _teachers = List<Map<String, dynamic>>.from(response.data['teachers'] ?? []);
        });
      }
    } catch (e) {
      developer.log('Error loading teachers: $e', name: 'TeacherManagement');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await _apiClient.get('/subjects');
      if (response.statusCode == 200) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(response.data['subjects'] ?? []);
        });
      }
    } catch (e) {
      developer.log('Error loading subjects: $e', name: 'TeacherManagement');
    }
  }

  Future<void> _addTeacher() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final response = await _apiClient.post('/admin/teachers', data: {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'subject_name': _selectedSubject,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _nameController.clear();
        _usernameController.clear();
        _passwordController.clear();
        setState(() {
          _selectedSubject = null;
        });
        _loadTeachers();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add teacher');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding teacher: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetTeacherPassword(int teacherId, String teacherName) async {
    final passwordController = TextEditingController();
    
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for $teacherName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter new password for $teacherName:'),
            SizedBox(height: 16.h),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.trim().isNotEmpty) {
                Navigator.pop(context, passwordController.text.trim());
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );

    if (newPassword != null) {
      try {
        final response = await _apiClient.post('/admin/teachers/$teacherId/reset-password', data: {
          'new_password': newPassword,
        });

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Password reset successfully for $teacherName'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          throw Exception(response.data['error'] ?? 'Failed to reset password');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting password: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTeacher(int teacherId, String teacherName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete $teacherName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _apiClient.delete('/admin/teachers/$teacherId');
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Teacher deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          _loadTeachers();
        } else {
          throw Exception(response.data['error'] ?? 'Failed to delete teacher');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting teacher: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add Teacher Form
                Container(
                  padding: EdgeInsets.all(16.w),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Teacher',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Teacher Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.account_circle),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Subject (Optional)',
                                prefixIcon: Icon(Icons.book),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No Subject'),
                                ),
                                ..._subjects.map((subject) {
                                  return DropdownMenuItem(
                                    value: subject['subject_name'],
                                    child: Text(subject['subject_name']),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubject = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addTeacher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: const Text('Add Teacher'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Teachers List
                Expanded(
                  child: _teachers.isEmpty
                      ? const Center(
                          child: Text('No teachers found'),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  teacher['name'] ?? 'Unknown',
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Username: ${teacher['username'] ?? 'N/A'}'),
                                    if (teacher['subjects'] != null)
                                      Text('Subjects: ${teacher['subjects']}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.lock_reset, color: AppColors.warning),
                                      onPressed: () => _resetTeacherPassword(
                                        teacher['teacher_id'],
                                        teacher['name'] ?? 'Unknown',
                                      ),
                                      tooltip: 'Reset Password',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.error),
                                      onPressed: () => _deleteTeacher(
                                        teacher['teacher_id'],
                                        teacher['name'] ?? 'Unknown',
                                      ),
                                      tooltip: 'Delete Teacher',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}