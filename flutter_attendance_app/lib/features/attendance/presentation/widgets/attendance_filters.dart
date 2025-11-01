import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';

class AttendanceFilters extends StatefulWidget {
  final String? selectedSubject;
  final DateTime? selectedDate;
  final Function({String? subject, DateTime? date}) onFiltersChanged;

  const AttendanceFilters({
    super.key,
    this.selectedSubject,
    this.selectedDate,
    required this.onFiltersChanged,
  });

  @override
  State<AttendanceFilters> createState() => _AttendanceFiltersState();
}

class _AttendanceFiltersState extends State<AttendanceFilters> {
  String? _selectedSubject;
  DateTime? _selectedDate;
  List<String> _subjects = ['All Subjects'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.selectedSubject;
    _selectedDate = widget.selectedDate;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.29.54:5000/api/subjects'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subjects = List<Map<String, dynamic>>.from(data['subjects']);
        setState(() {
          _subjects = ['All Subjects'] + subjects.map((s) => s['subject_name'] as String).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      developer.log('Error loading subjects: $e', name: 'AttendanceFilters');
      setState(() {
        _subjects = ['All Subjects', 'Computer Science', 'Mathematics', 'Physics'];
        _isLoading = false;
      });
    }
  }

  void _updateFilters() {
    widget.onFiltersChanged(
      subject: _selectedSubject == 'All Subjects' ? null : _selectedSubject,
      date: _selectedDate,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _updateFilters();
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
    _updateFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Subject Filter
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<String>(
                initialValue: _selectedSubject ?? 'All Subjects',
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
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
                  _updateFilters();
                },
              ),
        
        SizedBox(height: 12.h),
        
        // Date Filter
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                              : 'Select Date',
                          style: AppTextStyles.body2.copyWith(
                            color: _selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _clearDate,
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}