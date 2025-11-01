import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/datasources/student_profile_remote_datasource.dart';
import '../../data/models/student_profile_model.dart';
import 'student_profile_page.dart';

class StudentSearchPage extends StatefulWidget {
  const StudentSearchPage({super.key});

  @override
  State<StudentSearchPage> createState() => _StudentSearchPageState();
}

class _StudentSearchPageState extends State<StudentSearchPage> {
  final _searchController = TextEditingController();
  late final StudentProfileRemoteDatasource _datasource;
  
  List<StudentSearchModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _datasource = StudentProfileRemoteDatasource(apiClient: getIt.get<ApiClient>());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchStudents() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name or roll number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _datasource.searchStudents(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Student Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter name or roll number',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (_) => _searchStudents(),
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 100.w,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'Search for students by name or roll number',
              style: AppTextStyles.body1.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No students found',
              style: AppTextStyles.h3.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final student = _searchResults[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 28.r,
              child: Text(
                student.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.name,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text('Roll No: ${student.rollNo}'),
                Text('${student.course} - Year ${student.year} - ${student.division}'),
                if (student.hasFaceEncoding)
                  Row(
                    children: [
                      Icon(Icons.verified, size: 14.sp, color: Colors.green),
                      SizedBox(width: 4.w),
                      Text(
                        'Face Trained',
                        style: TextStyle(color: Colors.green, fontSize: 12.sp),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfilePage(studentId: student.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
