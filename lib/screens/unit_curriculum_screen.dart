import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import '../models/unit_model.dart';
import '../models/lesson_content_model.dart';
import '../services/auth_service.dart';
import '../services/unit_service.dart';
import '../screens/video_player_screen.dart';
import '../screens/quiz_viewer_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../utils/quiz_pass_config.dart';

class UnitCurriculumScreen extends StatefulWidget {
  final Unit unit;

  const UnitCurriculumScreen({
    super.key,
    required this.unit,
  });

  @override
  State<UnitCurriculumScreen> createState() => _UnitCurriculumScreenState();
}

class _UnitCurriculumScreenState extends State<UnitCurriculumScreen> {
  Map<String, dynamic>? _unitTree;
  bool _isLoading = true;
  String? _error;
  final Set<int> _expandedUnits = {};

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadUnitTree();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  Future<void> _loadUnitTree() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await UnitService.getUnitTreeWithProgress(
        unitId: widget.unit.unitId,
        token: token,
      );

      if (response != null && response['success'] == true) {
        setState(() {
          _unitTree = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response?['message'] ?? 'Failed to load curriculum';
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : _unitTree == null
                            ? _buildEmptyState()
                            : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE8DFCA), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38026B).withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button on the left
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF38026B), size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title in center
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Lecture content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.unit.unitName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF38026B),
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Refresh button on the right
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38026B).withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF38026B), size: 20),
              onPressed: _loadUnitTree,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final lessons = _unitTree?['lessons'] as List<dynamic>? ?? [];
    
    return RefreshIndicator(
      onRefresh: _loadUnitTree,
      color: const Color(0xFF38026B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          return _buildLessonItem(lessons[index], index);
        },
      ),
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson, int lessonIndex) {
    final lessonName = lesson['lessonName'] as String? ?? 'Lesson';
    final lessonTitle = lesson['titel'] as String?;
    final lessonType = lesson['type'] as String?;
    final isVideo = lessonType == 'Video';
    final isQuiz = lessonType == 'Quiz';
    final isFile = lessonType == 'File';
    final isCompleted = lesson['isCompleted'] == true;
    final isQuizSubmitted = lesson['isQuizSubmitted'] == true;
    final lessonId = lesson['id'] as int;
    final isRetake = parseQuizBoolNullable(lesson['isRetake'] ?? lesson['IsRetake']);
    final isQuizRetakeBlocked =
        isQuiz && isQuizSubmitted && isRetake == false;

    final isDone = isVideo ? isCompleted : isQuizSubmitted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDone
              ? [const Color(0xFFD4F1E8), const Color(0xFFC8EBE0)]
              : [const Color(0xFFE8EEF4), const Color(0xFFDDE6ED)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone 
              ? const Color(0xFF9FD9C3).withValues(alpha: 0.4)
              : const Color(0xFFB0C4DE).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isQuizRetakeBlocked
              ? null
              : () {
            if (isQuiz) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizViewerScreen(
                    lessonId: lessonId,
                    lessonName: lessonName,
                    treeQuizOverrides: QuizLessonTreeOverrides.fromLessonMap(
                      Map<String, dynamic>.from(lesson),
                    ),
                  ),
                ),
              ).then((_) {
                _loadUnitTree();
              });
            } else if (isFile) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                    lessonId: lessonId,
                    lessonName: lessonName,
                  ),
                ),
              ).then((_) {
                _loadUnitTree();
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    lessonId: lessonId,
                    lessonName: lessonName,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF7EC4A6)
                        : isVideo
                            ? const Color(0xFF38026B)
                            : isFile
                                ? const Color(0xFFE91E63)
                                : const Color(0xFFA8B8C8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isDone
                                ? const Color(0xFF7EC4A6)
                                : isVideo
                                    ? const Color(0xFF38026B)
                                    : isFile
                                        ? const Color(0xFFE91E63)
                                        : const Color(0xFFA8B8C8))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : isVideo
                            ? Icons.play_circle_filled_rounded
                            : isFile
                                ? Icons.picture_as_pdf_rounded
                                : Icons.quiz_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lessonName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A4A4A),
                          fontFamily: 'Cairo',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isVideo
                                  ? const Color(0xFFD6E4F0).withValues(alpha: 0.7)
                                  : const Color(0xFFE0E7ED).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isVideo ? 'Video' : 'Quiz',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isVideo ? const Color(0xFF5B7A9A) : const Color(0xFF7A8FA5),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(lessonIndex + 1).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDone ? const Color(0xFF7EC4A6) : const Color(0xFF38026B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading content...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFF87171),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUnitTree,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38026B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF38026B).withValues(alpha: 0.2),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFCBDCEB),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.school,
                size: 48,
                color: Color(0xFF38026B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No content available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'No lessons found in this lecture',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
