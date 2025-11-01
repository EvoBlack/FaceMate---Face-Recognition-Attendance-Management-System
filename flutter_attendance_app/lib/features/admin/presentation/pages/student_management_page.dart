import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/network/api_client.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _divisionController = TextEditingController();
  final _subdivisionController = TextEditingController();
  
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = getIt.get<ApiClient>();
    _loadStudents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _divisionController.dispose();
    _subdivisionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.get('/students');
      if (response.statusCode == 200) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response.data['students'] ?? []);
        });
      }
    } catch (e) {
      developer.log('Error loading students: $e', name: 'StudentManagement');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addStudent() async {
    if (_nameController.text.trim().isEmpty ||
        _rollNoController.text.trim().isEmpty ||
        _courseController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final response = await _apiClient.post('/admin/students', data: {
        'name': _nameController.text.trim(),
        'roll_no': _rollNoController.text.trim(),
        'course': _courseController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? 1,
        'division': _divisionController.text.trim().isEmpty ? null : _divisionController.text.trim(),
        'subdivision': _subdivisionController.text.trim().isEmpty ? null : _subdivisionController.text.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _nameController.clear();
        _rollNoController.clear();
        _courseController.clear();
        _yearController.clear();
        _divisionController.clear();
        _subdivisionController.clear();
        _loadStudents();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add student');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding student: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteStudent(int studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete $studentName?'),
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
        final response = await _apiClient.delete('/admin/students/$studentId');
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          _loadStudents();
        } else {
          throw Exception(response.data['error'] ?? 'Failed to delete student');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting student: $e'),
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
        title: const Text('Student Management'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add Student Form
                Container(
                  padding: EdgeInsets.all(16.w),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Student',
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
                                labelText: 'Student Name *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _rollNoController,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number *',
                                prefixIcon: Icon(Icons.numbers),
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
                              controller: _courseController,
                              decoration: const InputDecoration(
                                labelText: 'Course *',
                                prefixIcon: Icon(Icons.school),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Year *',
                                prefixIcon: Icon(Icons.calendar_today),
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
                              controller: _divisionController,
                              decoration: const InputDecoration(
                                labelText: 'Division',
                                prefixIcon: Icon(Icons.class_),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextField(
                              controller: _subdivisionController,
                              decoration: const InputDecoration(
                                labelText: 'Subdivision',
                                prefixIcon: Icon(Icons.group),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: const Text('Add Student'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Students List
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text('No students found'),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final hasFaceEncoding = student['has_face_encoding'] == 1;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasFaceEncoding ? AppColors.success : AppColors.warning,
                                  child: Icon(
                                    hasFaceEncoding ? Icons.face : Icons.face_retouching_natural,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${student['name']} (${student['roll_no']})',
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${student['course']} - Year ${student['year']}'),
                                    if (student['division'] != null)
                                      Text('Division: ${student['division']}${student['subdivision'] ?? ''}'),
                                    Text(
                                      hasFaceEncoding ? 'Face Trained ✓' : 'Face Not Trained',
                                      style: TextStyle(
                                        color: hasFaceEncoding ? AppColors.success : AppColors.warning,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.error),
                                  onPressed: () => _deleteStudent(
                                    student['id'],
                                    student['name'] ?? 'Unknown',
                                  ),
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