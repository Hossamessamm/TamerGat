import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../models/course_model.dart';
import '../models/course_tree_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../widgets/enrollment_dialog.dart';
import '../widgets/shimmer_curriculum_card.dart';
import '../config/api_config.dart';
import 'course_curriculum_screen.dart';
import 'checkout_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  CourseTree? _courseTree;
  bool _isLoading = true;
  String? _error;
  bool? _isEnrolled;

  static const _primary = Color(0xFF38026B);
  static const _primaryLight = Color(0xFF6A1B9A);
  static const _bgLight = Color(0xFFF6F7F8);
  static const _surface = Color(0xFFFAFBFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadCourseTree().then((_) => _checkEnrollment());
  }

  Future<void> _refresh() async {
    await _loadCourseTree();
    await _checkEnrollment();
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
      final response = await CourseService.getCourseTree(
        courseId: widget.course.id,
        token: authService.token,
        authService: authService,
      );

      if (!mounted) return;
      setState(() {
        if (response != null && response.success && response.data != null) {
          _courseTree = response.data;
          _error = null;
        } else {
          _courseTree = null;
          _error = response?.message ?? 'Failed to load content';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
        _courseTree = null;
      });
    }
  }

  Future<void> _checkEnrollment() async {
    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;
      final userId = authService.currentUser?.id;

      if (token == null || userId == null) {
        if (mounted) setState(() => _isEnrolled = false);
        return;
      }

      final isEnrolled = await CourseService.isEnrolled(
        studentId: userId,
        courseId: widget.course.id,
        token: token,
        authService: authService,
      );

      if (mounted) setState(() => _isEnrolled = isEnrolled);
    } catch (e) {
      if (mounted) setState(() => _isEnrolled = false);
    }
  }

  Lesson? get _firstLesson {
    if (_courseTree == null || _courseTree!.units.isEmpty) return null;
    for (final u in _courseTree!.units) {
      if (u.lessons.isNotEmpty) return u.lessons.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final hPad = 16.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            color: _primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildStickyHeader(padding, hPad),
                SliverToBoxAdapter(child: _buildCourseHero(hPad)),
                SliverToBoxAdapter(child: _buildCourseDescriptionAndPrice(hPad)),
                SliverToBoxAdapter(
                  key: ValueKey('content_${_courseTree != null}_$_isLoading'),
                  child: _buildCurriculumTab(hPad),
                ),
              ],
            ),
          ),
          if (_isEnrolled != null) _buildStickyCta(hPad),
        ],
      ),
    ),
    );
  }

  Widget _buildStickyHeader(EdgeInsets padding, double hPad) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      expandedHeight: 0,
      backgroundColor: _bgLight.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textSecondary),
            ),
          ),
        ),
      ),
      title: Text(
        widget.course.courseName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildCourseHero(double hPad) {
    final hasImage = widget.course.imagePath != null &&
        widget.course.imagePath!.isNotEmpty &&
        ApiConfig.getImageUrl(widget.course.imagePath!).isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primary.withValues(alpha: 0.15),
                      _primaryLight.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: hasImage
                    ? Image.network(
                        ApiConfig.getImageUrl(widget.course.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(Icons.menu_book_rounded, size: 64, color: _primary.withValues(alpha: 0.3)),
    );
  }

  Widget _buildCourseDescriptionAndPrice(double hPad) {
    final hasDescription = widget.course.description != null &&
        widget.course.description!.trim().isNotEmpty;
    final hasPrice = widget.course.price != null;

    if (!hasDescription && !hasPrice) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPrice) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.paid_rounded, size: 20, color: _primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.course.price! == 0
                        ? 'Free'
                        : '${widget.course.price!.toStringAsFixed(2)} EGP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDescription) const SizedBox(height: 16),
          ],
          if (hasDescription) ...[
            const Text(
              'About this course',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course.description!,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurriculumTab(double hPad) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.all(hPad),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerCurriculumCard(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: _primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Material(
              color: _primary,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              child: InkWell(
                onTap: _loadCourseTree,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_courseTree == null || _courseTree!.units.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'No content available',
              style: TextStyle(fontSize: 16, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: hPad),
        ..._courseTree!.units.asMap().entries.map((entry) {
          final unitIndex = entry.key;
          final unit = entry.value;
          final unitLessons = unit.lessons;
          final completedInUnit = 0;

          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_primary, _primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unit ${unitIndex + 1}: ${unit.unitName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primary.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        '$completedInUnit/${unitLessons.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...unitLessons.asMap().entries.map((le) {
                  final idx = le.key;
                  final lesson = le.value;
                  final isLast = idx == unitLessons.length - 1;

                  return _buildTimelineLesson(
                    lesson: lesson,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildTimelineLesson({
    required Lesson lesson,
    required bool isLast,
  }) {
    final type = lesson.type.toLowerCase();
    IconData iconData;
    String typeLabel;
    if (type == 'quiz') {
      iconData = Icons.quiz_rounded;
      typeLabel = 'Quiz';
    } else if (type == 'file' || type == 'pdf') {
      iconData = Icons.article_rounded;
      typeLabel = 'Reading';
    } else {
      iconData = Icons.play_circle_rounded;
      typeLabel = 'Video';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 22,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.lessonName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(iconData, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCta(double hPad) {
    final firstLesson = _firstLesson;
    final resumeText = _isEnrolled!
        ? (firstLesson?.lessonName ?? 'Continue learning')
        : (widget.course.price != null && (widget.course.price ?? 0) > 0)
            ? 'Buy now'
            : 'Enroll in course';
    final isPaidCourse = widget.course.price != null && (widget.course.price ?? 0) > 0;
    final ctaColor = _isEnrolled! ? _primary : const Color(0xFF059669);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bgLight.withValues(alpha: 0),
                  _bgLight.withValues(alpha: 0.97),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (_isEnrolled!) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseCurriculumScreen(course: widget.course),
                      ),
                    );
                  } else {
                    if (isPaidCourse) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(course: widget.course),
                        ),
                      );
                      await _checkEnrollment();
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => EnrollmentDialog(
                          courseId: widget.course.id,
                          teacherId: widget.course.teacherId,
                          teacherName: widget.course.teacherName,
                          onEnrollmentSuccess: () {
                            setState(() => _isEnrolled = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enrolled in course successfully')),
                            );
                          },
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isEnrolled!
                          ? [_primary, _primaryLight]
                          : [const Color(0xFF059669), const Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ctaColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: ctaColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _isEnrolled!
                                  ? Icons.play_arrow_rounded
                                  : isPaidCourse
                                      ? Icons.payment_rounded
                                      : Icons.add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEnrolled! ? 'Continue learning' : 'Start now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  resumeText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

