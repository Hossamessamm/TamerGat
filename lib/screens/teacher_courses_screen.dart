import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../services/teacher_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/shimmer_grade_card.dart';
import 'grade_courses_screen.dart';

class TeacherCoursesScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherCoursesScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  List<Subject> _subjects = [];
  bool _isLoadingSubjects = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadSubjects();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;
    
    if (token != null) {
      final response = await TeacherService.getSubjectsForTeacher(
        teacherId: widget.teacher.id,
        token: token,
        authService: authService,
      );
      
      if (mounted && response != null && response.success) {
        setState(() {
          _subjects = response.data;
          _isLoadingSubjects = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _error = response?.message ?? 'Failed to load subjects';
            _isLoadingSubjects = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _error = 'Authentication error';
          _isLoadingSubjects = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Simple App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
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
                  child: Text(
                    widget.teacher.name,
                    style: const TextStyle(
                      color: Color(0xFF1A1F36),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Balance space on the left for RTL
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF38026B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'الصفوف الدراسية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          _isLoadingSubjects
              ? SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerGradeCard(),
                      childCount: 5,
                    ),
                  ),
                )
              : _error != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoadingSubjects = true;
                                  _error = null;
                                });
                                _loadSubjects();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _subjects.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No grades available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final subject = _subjects[index];
                                return _buildGradeCard(subject, index);
                              },
                              childCount: _subjects.length,
                            ),
                          ),
                        ),
        ],
      ),
      ),
    );
  }

  Widget _buildGradeCard(Subject subject, int index) {
    final colors = [
      [const Color(0xFF6A1B9A), const Color(0xFF38026B)],
      [const Color(0xFF48C9B0), const Color(0xFF16A085)],
      [const Color(0xFFAF7AC5), const Color(0xFF8E44AD)],
      [const Color(0xFFEC7063), const Color(0xFFE74C3C)],
      [const Color(0xFFF39C12), const Color(0xFFE67E22)],
    ];
    
    final colorPair = colors[index % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradeCoursesScreen(
                  subject: subject,
                  teacherId: widget.teacher.id,
                  teacherName: widget.teacher.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colorPair,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Grade Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.description ?? subject.gradeName ?? 'Grade',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F36),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط للدخول',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon (reversed for RTL)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorPair[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: colorPair[0],
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
