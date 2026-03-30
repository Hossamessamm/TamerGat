import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';
import '../models/course_tree_progress_model.dart';
import '../models/lesson_content_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../screens/video_player_screen.dart';
import '../screens/quiz_viewer_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/shimmer_curriculum_card.dart';
import '../config/api_config.dart';
import 'package:tamergat_app/utils/quiz_pass_config.dart';

class CourseCurriculumScreen extends StatefulWidget {
  final Course course;

  const CourseCurriculumScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends State<CourseCurriculumScreen> {
  CourseTreeWithProgress? _courseTree;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadCourseTree();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  Future<void> _loadCourseTree() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.token == null) {
        if (mounted) setState(() {
          _error = 'You must be logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await CourseService.getCourseTreeWithProgress(
        courseId: widget.course.id,
        token: authService.token,
        authService: authService,
      );

      if (!mounted) return;
      final tree = response?.data;
      if (response != null && response.success && tree != null) {
        for (final unit in tree.units) {
          for (final lesson in unit.lessons) {
            if (lesson.type == LessonType.quiz && lesson.passDegree != null) {
              QuizPassDegreeCache.remember(lesson.id, lesson.passDegree!);
            }
          }
        }
      }
      setState(() {
        if (response != null && response.success && response.data != null) {
          _courseTree = response.data;
          _error = null;
        } else {
          _error = response?.message ?? 'Failed to load content';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطأ: $e';
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String? path) {
    return ApiConfig.getImageUrl(path);
  }

  /// Group link from API (course tree) or from passed course
  String? get _groupLink =>
      _courseTree?.groupLink ?? widget.course.groupLink;

  Future<void> _openWhatsAppGroup() async {
    final link = _groupLink;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Full course order: units and lessons sorted by [order] (same progression used for locks).
  static List<LessonTree> _flattenLessonsInCourseOrder(CourseTreeWithProgress tree) {
    final units = [...tree.units]..sort((a, b) => a.order.compareTo(b.order));
    final out = <LessonTree>[];
    for (final u in units) {
      final lessons = [...u.lessons]..sort((a, b) => a.order.compareTo(b.order));
      out.addAll(lessons);
    }
    return out;
  }

  /// Nearest quiz before [lesson] in full course order (may be in an earlier unit).
  static LessonTree? _nearestPreviousQuiz(LessonTree lesson, List<LessonTree> flat) {
    final idx = flat.indexWhere((l) => l.id == lesson.id);
    if (idx <= 0) return null;
    for (var j = idx - 1; j >= 0; j--) {
      if (flat[j].type == LessonType.quiz) return flat[j];
    }
    return null;
  }

  void _showQuizLockDialog(BuildContext context, {required double passPercent}) {
    final p = passPercent % 1 == 0
        ? passPercent.toStringAsFixed(0)
        : passPercent.toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFFFF9800), size: 28),
              SizedBox(width: 12),
              Text('Content locked'),
            ],
          ),
          content: Text(
            'You need to score $p% or more on the previous quiz to unlock this content.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRetakeNotAllowedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFFFF9800), size: 28),
              SizedBox(width: 12),
              Text('Quiz closed'),
            ],
          ),
          content: const Text(
            'This quiz does not allow retakes. You have already completed it.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          title: Text(
            widget.course.courseName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        floatingActionButton: _groupLink != null && _groupLink!.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _openWhatsAppGroup,
                backgroundColor: const Color(0xFF25D366),
                icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'Join to community',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              )
            : null,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // Content
            if (_isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerCurriculumCard(),
                  childCount: 3,
                ),
              )
            else if (_error != null)
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
                        onPressed: _loadCourseTree,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_courseTree != null && _courseTree!.units.isNotEmpty)
              Builder(
                builder: (context) {
                  final flatLessons =
                      _flattenLessonsInCourseOrder(_courseTree!);
                  final sortedUnits = [..._courseTree!.units]
                    ..sort((a, b) => a.order.compareTo(b.order));
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final unit = sortedUnits[index];
                        return _buildUnitCard(unit, index, flatLessons);
                      },
                      childCount: sortedUnits.length,
                    ),
                  );
                },
              )
            else
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No content available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(
    UnitTree unit,
    int unitIndex,
    List<LessonTree> flatLessonsInCourseOrder,
  ) {
    final sortedLessons = [...unit.lessons]
      ..sort((a, b) => a.order.compareTo(b.order));
    final completedLessons = sortedLessons.where((l) => l.isDone).length;
    final totalLessons = sortedLessons.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.unitName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 16,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$totalLessons Lessons',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$completedLessons Completed',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: sortedLessons.asMap().entries.map((entry) {
            return _buildLessonTile(
              entry.value,
              unitIndex,
              entry.key,
              flatLessonsInCourseOrder,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    LessonTree lesson,
    int unitIndex,
    int lessonIndex,
    List<LessonTree> flatLessonsInCourseOrder,
  ) {
    final isVideo = lesson.type == LessonType.video;
    final isCompleted = lesson.isDone;
    final isQuizSubmitted = lesson.type == LessonType.quiz && lesson.isQuizSubmitted == true;
    // Lock any lesson after a failed quiz until that quiz is passed — scans full course order
    // (so a video after a failed quiz does not "unlock" the next unit).
    final previousQuiz =
        _nearestPreviousQuiz(lesson, flatLessonsInCourseOrder);
    final isLockedAfterQuiz =
        previousQuiz != null && !previousQuiz.isQuizPassed;
    final isQuizRetakeBlocked = lesson.isQuizRetakeBlocked;
    final isLessonVisuallyLocked = isLockedAfterQuiz || isQuizRetakeBlocked;

    // Determine colors based on lesson type
    Color primaryColor;
    Color backgroundColor;
    IconData iconData;
    final bool useCustomIcon = lesson.type == LessonType.quiz || lesson.type == LessonType.video;

    if (lesson.type == LessonType.quiz) {
      primaryColor = const Color(0xFFFF9800);
      backgroundColor = const Color(0xFFFFF8F0);
      iconData = Icons.quiz_rounded;
    } else if (lesson.type == LessonType.file) {
      primaryColor = const Color(0xFFE91E63);
      backgroundColor = const Color(0xFFFCE4EC);
      iconData = Icons.picture_as_pdf_rounded;
    } else {
      primaryColor = AppTheme.primaryColor;
      backgroundColor = const Color(0xFFEFF6FF);
      iconData = Icons.play_circle_filled_rounded;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLessonVisuallyLocked
              ? Colors.grey.withOpacity(0.3)
              : isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLockedAfterQuiz) {
              _showQuizLockDialog(
                context,
                passPercent: previousQuiz.passDegree ??
                    QuizPassDegreeCache.forLesson(previousQuiz.id) ??
                    kDefaultQuizPassDegreePercent,
              );
              return;
            }
            if (isQuizRetakeBlocked) {
              _showRetakeNotAllowedDialog(context);
              return;
            }
            if (lesson.type == LessonType.quiz) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizViewerScreen(
                    lessonId: lesson.id,
                    lessonName: lesson.lessonName ?? 'Quiz',
                    treeQuizOverrides:
                        QuizLessonTreeOverrides.fromLessonTree(lesson),
                  ),
                ),
              ).then((_) => _loadCourseTree());
            } else if (lesson.type == LessonType.file) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                    lessonId: lesson.id,
                    lessonName: lesson.lessonName ?? 'PDF Lesson',
                  ),
                ),
              ).then((_) => _loadCourseTree());
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    lessonId: lesson.id,
                    lessonName: lesson.lessonName ?? 'Lesson',
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isLessonVisuallyLocked ? 0.75 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon container (custom image for video/quiz, icon for file)
                  Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: useCustomIcon ? Colors.transparent : null,
                    gradient: useCustomIcon ? null : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLessonVisuallyLocked
                          ? [Colors.grey, Colors.grey.shade600]
                          : isCompleted
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [primaryColor, primaryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted ? const Color(0xFF10B981) : primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Center(
                          child: useCustomIcon
                              ? Image.asset(
                                  lesson.type == LessonType.quiz
                                      ? 'assets/icons/quiz_icon.png'
                                      : 'assets/icons/video_icon.png',
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                )
                              : Icon(
                                  iconData,
                                  color: Colors.white,
                                  size: 26,
                                ),
                        ),
                        // Completion checkmark overlay
                        if (isCompleted)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 2),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF10B981),
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Lesson info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.lessonName ?? 'Untitled Lesson',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lesson.titel != null && lesson.titel!.isNotEmpty && lesson.titel != 'null') ...[
                        const SizedBox(height: 4),
                        Text(
                          lesson.titel!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge or arrow
                if (lesson.type == LessonType.quiz)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isQuizRetakeBlocked
                            ? [Colors.grey.shade600, Colors.grey.shade700]
                            : isQuizSubmitted
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : [const Color(0xFFFF9800), const Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isQuizRetakeBlocked
                                  ? Colors.grey
                                  : isQuizSubmitted
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFFF9800))
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isQuizRetakeBlocked
                              ? Icons.lock_outline
                              : isQuizSubmitted
                                  ? Icons.check_circle
                                  : Icons.quiz,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isQuizRetakeBlocked
                              ? 'Closed'
                              : isQuizSubmitted
                                  ? 'Done'
                                  : 'Quiz',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isLockedAfterQuiz)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
