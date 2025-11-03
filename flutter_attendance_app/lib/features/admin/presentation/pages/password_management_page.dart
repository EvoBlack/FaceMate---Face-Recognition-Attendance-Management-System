import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/app_config.dart';

class PasswordManagementPage extends StatefulWidget {
  const PasswordManagementPage({Key? key}) : super(key: key);

  @override
  State<PasswordManagementPage> createState() => _PasswordManagementPageState();
}

class _PasswordManagementPageState extends State<PasswordManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStudents(),
      _loadTeachers(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/students'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final studentsList = data['students'] as List?;
        
        if (studentsList != null) {
          setState(() {
            _students = studentsList
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e')),
      );
    }
  }

  Future<void> _loadTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/teachers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teachersList = data['teachers'] as List?;
        
        if (teachersList != null) {
          setState(() {
            _teachers = teachersList
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading teachers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load teachers: $e')),
      );
    }
  }

  Future<void> _resetPassword(String type, int id, String name) async {
    final password = _passwordController.text.trim();
    
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint = type == 'student' 
          ? '/admin/reset-student-password'
          : '/admin/reset-teacher-password';
      
      final idKey = type == 'student' ? 'student_id' : 'teacher_id';

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          idKey: id,
          'new_password': password,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully for $name'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to reset password';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResetDialog(String type, int id, String name) {
    _passwordController.text = '123456'; // Default password
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for $name'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter new password for $name',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _resetPassword(type, id, name);
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No students found'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStudents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        try {
          final student = _students[index];
          final name = student['name']?.toString() ?? 'Unknown';
          final rollNo = student['roll_no']?.toString() ?? 'N/A';
          final id = student['id'];
          final studentId = id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S'),
              ),
              title: Text(name),
              subtitle: Text('Roll No: $rollNo'),
              trailing: IconButton(
                onPressed: studentId > 0 ? () => _showResetDialog('student', studentId, name) : null,
                icon: const Icon(Icons.lock_reset),
                tooltip: 'Reset Password',
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildTeachersList() {
    if (_teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No teachers found'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTeachers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _teachers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        try {
          final teacher = _teachers[index];
          final name = teacher['name']?.toString() ?? 'Unknown';
          final id = teacher['teacher_id'];
          final teacherId = id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T'),
              ),
              title: Text(name),
              subtitle: Text('ID: ${teacherId > 0 ? teacherId : 'N/A'}'),
              trailing: IconButton(
                onPressed: teacherId > 0 ? () => _showResetDialog('teacher', teacherId, name) : null,
                icon: const Icon(Icons.lock_reset),
                tooltip: 'Reset Password',
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Students', icon: Icon(Icons.school)),
            Tab(text: 'Teachers', icon: Icon(Icons.person)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsList(),
                _buildTeachersList(),
              ],
            ),
    );
  }
}
