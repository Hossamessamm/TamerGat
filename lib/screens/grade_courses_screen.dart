import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../models/course_model.dart';
import '../models/subject_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../widgets/course_card.dart';
import '../widgets/shimmer_course_card.dart';
import '../utils/app_theme.dart';

class GradeCoursesScreen extends StatefulWidget {
  final Subject subject;
  final String teacherId;
  final String teacherName;

  const GradeCoursesScreen({
    super.key,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<GradeCoursesScreen> createState() => _GradeCoursesScreenState();
}

class _GradeCoursesScreenState extends State<GradeCoursesScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Course> _courses = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadCourses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
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


      // Remove spaces from grade name for API
      final gradeParam = widget.subject.gradeId;

      final response = await CourseService.getFilteredCourses(
        teacherId: widget.teacherId,
        gradeId: gradeParam,
        token: token,
        pageNumber: _currentPage,
        pageSize: _pageSize,
        active: true,
      );

      if (response != null) {
        setState(() {
          if (_currentPage == 1) {
            _courses = response.courses;
          } else {
            _courses.addAll(response.courses);
          }
          
          _hasMore = _currentPage < response.totalPages;
          if (_hasMore) {
            _currentPage++;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load courses';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Simple App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  // Back button on the right (appears right in RTL)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1F36), size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.subject.description ?? widget.subject.gradeName ?? 'Grade',
                          style: const TextStyle(
                            color: Color(0xFF1A1F36),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          widget.teacherName,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Balance space on the left for RTL
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Content
          if (_error != null && _courses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_courses.isEmpty && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading && _courses.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerCourseCard(),
                  childCount: 5,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CourseCard(course: _courses[index]),
                    );
                  },
                  childCount: _courses.length,
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
