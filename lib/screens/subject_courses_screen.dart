import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/subject_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../utils/app_theme.dart';
import '../widgets/course_card.dart';
import '../widgets/shimmer_course_card.dart';

class SubjectCoursesScreen extends StatefulWidget {
  final Subject subject;

  const SubjectCoursesScreen({super.key, required this.subject});

  @override
  State<SubjectCoursesScreen> createState() => _SubjectCoursesScreenState();
}

class _SubjectCoursesScreenState extends State<SubjectCoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCourses();
    });
  }

  Future<void> _loadCourses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await CourseService.getCoursesBySubjectId(
      subjectId: widget.subject.id,
      token: token,
      authService: authService,  // ✅ Pass authService for automatic token refresh
      pageNumber: 1,
      pageSize: 50,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response != null) {
        _courses = response.courses;
        _error = null;
      } else {
        _courses = [];
        _error = 'Failed to load courses';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.of(context).size.width >= 600 ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject.name.isNotEmpty ? widget.subject.name : 'Courses',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              children: List.generate(3, (_) => const ShimmerCourseCard()),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCourses,
                            child: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                )
              : _courses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'There are no courses in this subject yet',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        return CourseCard(course: _courses[index]);
                      },
                    ),
    );
  }
}
