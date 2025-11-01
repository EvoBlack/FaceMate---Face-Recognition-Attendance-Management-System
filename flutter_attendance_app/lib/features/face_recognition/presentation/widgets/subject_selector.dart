import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';

class SubjectSelector extends StatefulWidget {
  final Function(String) onSubjectSelected;

  const SubjectSelector({
    super.key,
    required this.onSubjectSelected,
  });

  @override
  State<SubjectSelector> createState() => _SubjectSelectorState();
}

class _SubjectSelectorState extends State<SubjectSelector> {
  String? _selectedSubject;
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('https://facemate-backend.onrender.com/api/subjects'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subjects = List<Map<String, dynamic>>.from(data['subjects']);
        setState(() {
          _subjects = subjects.map((s) => s['subject_name'] as String).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      developer.log('Error loading subjects: $e', name: 'SubjectSelector');
      setState(() {
        _subjects = ['Computer Science', 'Mathematics', 'Physics']; // Fallback
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Subject',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: InputDecoration(
                  hintText: 'Choose a subject',
                  prefixIcon: const Icon(Icons.subject),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                  if (value != null) {
                    widget.onSubjectSelected(value);
                  }
                },
              ),
      ],
    );
  }
}