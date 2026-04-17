import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../widgets/course_card.dart';
import '../utils/app_theme.dart';

class GradeCoursesByGradeScreen extends StatefulWidget {
  final String gradeIdOrName;

  const GradeCoursesByGradeScreen({
    super.key,
    required this.gradeIdOrName,
  });

  @override
  State<GradeCoursesByGradeScreen> createState() =>
      _GradeCoursesByGradeScreenState();
}

class _GradeCoursesByGradeScreenState extends State<GradeCoursesByGradeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;
  /// Shown when the list is empty but the request succeeded (e.g. API message for no courses).
  String? _emptyInfoMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _emptyInfoMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await CourseService.getCoursesByGradeId(
        gradeId: widget.gradeIdOrName,
        token: token,
        authService: authService,
      );

      if (!mounted) return;

      if (response != null) {
        setState(() {
          _courses = response.courses;
          _emptyInfoMessage =
              response.courses.isEmpty ? response.apiMessage : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load courses';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.gradeIdOrName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
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
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _emptyInfoMessage ?? 'No courses available for this grade',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CourseCard(course: _courses[index]),
        );
      },
    );
  }
}

