import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../widgets/course_card.dart';
import '../utils/app_theme.dart';

class EnrolledCoursesScreen extends StatefulWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  State<EnrolledCoursesScreen> createState() => _EnrolledCoursesScreenState();
}

class _EnrolledCoursesScreenState extends State<EnrolledCoursesScreen> {
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
    debugPrint('EnrolledCoursesScreen initialized');
    _loadCourses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
    debugPrint('Loading enrolled courses...');
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;
      final user = authService.currentUser;

      debugPrint('Token: ${token != null}, User: ${user?.id}');

      if (token == null || user == null) {
        setState(() {
          _error = 'You must be logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await CourseService.getEnrolledCourses(
        studentId: user.id,
        token: token,
        authService: authService,  // ✅ Pass authService for automatic token refresh
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      debugPrint('Enrolled courses response: ${response?.courses.length}');

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
      debugPrint('Error loading courses: $e');
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final isPortrait = screenSize.height > screenSize.width;
    final screenWidth = screenSize.width;
    final horizontalPadding = isTablet ? (screenWidth * 0.1).clamp(40.0, 120.0) : 16.0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'My courses',
              style: TextStyle(
                color: const Color(0xFF1A1F36),
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 22 : 18,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
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
                      'No enrolled courses yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            isTablet && !isPortrait
                ? SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, rowIndex) {
                          // Calculate the actual course indices for this row
                          final firstCourseIndex = rowIndex * 2;
                          final secondCourseIndex = firstCourseIndex + 1;
                          final hasSecondCourse = secondCourseIndex < _courses.length;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CourseCard(course: _courses[firstCourseIndex]),
                                ),
                                if (hasSecondCourse) const SizedBox(width: 20),
                                if (hasSecondCourse)
                                  Expanded(
                                    child: CourseCard(course: _courses[secondCourseIndex]),
                                  ),
                                if (!hasSecondCourse)
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          );
                        },
                        childCount: (_courses.length / 2).ceil(),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet && isPortrait ? horizontalPadding - 16 : horizontalPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isTablet && isPortrait ? 8 : 0,
                            ),
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
            
          // Bottom padding for navigation bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
    );
  }
}
