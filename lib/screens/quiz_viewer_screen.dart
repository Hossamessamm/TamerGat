import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:tamergat_app/utils/quiz_pass_config.dart';

import '../models/lesson_content_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../config/api_config.dart';

class QuizViewerScreen extends StatefulWidget {
  final int lessonId;
  final String lessonName;
  /// Quiz UI flags from course tree (`tree-course-with-progress`); merged with lesson content.
  final QuizLessonTreeOverrides? treeQuizOverrides;

  const QuizViewerScreen({
    super.key,
    required this.lessonId,
    required this.lessonName,
    this.treeQuizOverrides,
  });

  @override
  State<QuizViewerScreen> createState() => _QuizViewerScreenState();
}

class _QuizViewerScreenState extends State<QuizViewerScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _showSplash = true;
  String? _error;
  QuizLessonResponse? _quizData;
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  bool _showResults = false;
  int _score = 0;
  Map<int, bool> _flashcardAnswersShown = {}; // Track which flashcard questions have shown answer
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Map<int, AnimationController> _flipControllers = {}; // Animation controllers for flip buttons

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadQuizData();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _fadeController.dispose();
    // Dispose all flip controllers
    for (var controller in _flipControllers.values) {
      controller.dispose();
    }
    _flipControllers.clear();
    super.dispose();
  }

  String _formatPassPercent(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Shown on the results screen when the learner passes (tiered by %).
  String _motivationMessage(double percentage) {
    if (percentage >= 100) {
      return '🏆 Perfect score! You nailed every question — amazing!';
    }
    if (percentage >= 95) {
      return '🌟 Outstanding! Almost flawless — keep shining!';
    }
    if (percentage >= 90) {
      return '🔥 Excellent work! You’re on fire — keep it up!';
    }
    if (percentage >= 80) {
      return '💪 Great job! Strong result — proud of you!';
    }
    return '✨ Well done! You passed — every step counts!';
  }

  Widget _buildMotivationBanner(double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFECFDF5),
            const Color(0xFFD1FAE5).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _motivationMessage(percentage),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF065F46),
        ),
      ),
    );
  }

  Future<void> _loadQuizData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        setState(() {
          _error = 'Please login to view this quiz';
          _isLoading = false;
        });
        return;
      }

      final response = await CourseService.getLessonContent(
        lessonId: widget.lessonId,
        token: token,
      );

      if (response is QuizLessonResponse && response.success) {
        final merged = response.mergeWithTreeOverrides(widget.treeQuizOverrides);
        QuizPassDegreeCache.remember(widget.lessonId, merged.passDegree);
        setState(() {
          _quizData = merged;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load quiz';
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

  void _startQuiz() {
    setState(() {
      _showSplash = false;
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _showResults = false;
      _score = 0;
      _flashcardAnswersShown.clear();
      // Dispose flip controllers
      for (var controller in _flipControllers.values) {
        controller.dispose();
      }
      _flipControllers.clear();
    });
    _fadeController.forward(from: 0);
  }

  void _retakeQuiz() {
    setState(() {
      _showResults = false;
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _score = 0;
      _flashcardAnswersShown.clear();
      // Dispose flip controllers
      for (var controller in _flipControllers.values) {
        controller.dispose();
      }
      _flipControllers.clear();
      _showSplash = true;
    });
    _fadeController.forward(from: 0);
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < (_quizData?.data?.length ?? 0) - 1) {
      setState(() {
        _currentQuestionIndex++;
        // Reset flashcard answer state for next question
        _flashcardAnswersShown[_currentQuestionIndex] = false;
        // Reset flip animation for next question
        final controller = _flipControllers[_currentQuestionIndex];
        if (controller != null) {
          controller.reset();
        }
      });
      _fadeController.forward(from: 0);
    } else {
      _submitQuiz();
    }
  }

  void _showFlashcardAnswer() {
    // Show the answer for flashcard question
    setState(() {
      _flashcardAnswersShown[_currentQuestionIndex] = true;
      final controller = _getFlipController(_currentQuestionIndex);
      controller.forward();
    });
  }

  AnimationController _getFlipController(int index) {
    if (!_flipControllers.containsKey(index)) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _flipControllers[index] = controller;
      if (_flashcardAnswersShown[index] == true) {
        controller.value = 1.0;
      }
    }
    return _flipControllers[index]!;
  }

  Widget _buildFlipButton(QuestionDto question, bool showFlashcardAnswer, int totalQuestions) {
    final flipController = _getFlipController(_currentQuestionIndex);
    final flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: flipController,
        curve: Curves.easeInOut,
      ),
    );

    final answerText = question.answers.firstWhere((a) => a.isCorrect).text;

    return SizedBox(
      width: double.infinity,
      height: 80,
      child: AnimatedBuilder(
        animation: flipAnimation,
        builder: (context, child) {
          final isFlipped = flipAnimation.value >= 0.5;
          final rotationY = flipAnimation.value * 3.14159; // 180 degrees in radians
          final scale = (1 - (flipAnimation.value * 0.5 - 0.25).abs() * 2).clamp(0.3, 1.0);

          return GestureDetector(
            onTap: () {
              // Only flip to show answer, navigation is handled by the Next Question button
              if (!showFlashcardAnswer) {
                _showFlashcardAnswer();
              }
            },
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(rotationY),
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isFlipped
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        )
                      : null,
                  color: !isFlipped ? const Color(0xFF10B981) : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(isFlipped ? -1.0 : 1.0, 1.0, 1.0),
                  child: Opacity(
                    opacity: scale,
                    child: Center(
                      child: isFlipped
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                answerText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Show Answer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _fadeController.forward(from: 0);
    }
  }

  Future<void> _submitQuiz() async {
    // Calculate score
    int correctAnswers = 0;
    final totalQuestions = _quizData?.data?.length ?? 0;
    final passDegree =
        _quizData?.passDegree ?? kDefaultQuizPassDegreePercent;

    _quizData?.data?.asMap().forEach((index, question) {
      final selectedAnswerIndex = _selectedAnswers[index];
      if (selectedAnswerIndex != null && question.answers[selectedAnswerIndex].isCorrect) {
        correctAnswers++;
      }
    });

    // Calculate percentage score (0-100)
    final percentageScore = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 0.0;

    final passed = percentageScore >= passDegree;

    setState(() {
      _score = correctAnswers;
      _showResults = true;
    });
    _fadeController.forward(from: 0);

    // Submit quiz result to API (server decides persistence; we never trust URL-only success)
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token != null) {
        final response = await CourseService.submitQuiz(
          lessonId: widget.lessonId,
          score: percentageScore,
          notes: 'passed:$passed;passDegree:$passDegree',
          token: token,
        );

        if (!mounted) return;

        _showSubmissionDialog(
          success: response.success,
          message: response.success
              ? 'Quiz submitted successfully'
              : (response.message.isEmpty
                  ? 'Failed to submit quiz'
                  : response.message),
          passed: passed,
          passDegree: passDegree,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSubmissionDialog(
        success: false,
        message: 'Connection error',
      );
    }
  }

  void _showSubmissionDialog({
    required bool success,
    required String message,
    bool? passed,
    double? passDegree,
  }) {
    final submitPassed = passed;
    final requiredPassPercent = passDegree;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: !success
                        ? const Color(0xFFFEE2E2)
                        : (passed == false
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFD1FAE5)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    !success
                        ? Icons.error_rounded
                        : (passed == false
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded),
                    size: 50,
                    color: !success
                        ? const Color(0xFFEF4444)
                        : (passed == false
                            ? const Color(0xFFD97706)
                            : const Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  !success
                      ? 'Error'
                      : (passed == false
                          ? 'Submitted — not passed'
                          : 'Quiz Submitted'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: !success
                        ? const Color(0xFFEF4444)
                        : (passed == false
                            ? const Color(0xFFD97706)
                            : const Color(0xFF10B981)),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (!success) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (success &&
                    submitPassed != null &&
                    requiredPassPercent != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    submitPassed
                        ? 'You passed. Required: ${_formatPassPercent(requiredPassPercent)}%.'
                        : 'You did not reach ${_formatPassPercent(requiredPassPercent)}%. '
                            'Complete the required score to unlock the next lessons.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: submitPassed
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !success
                          ? const Color(0xFFEF4444)
                          : (passed == false
                              ? const Color(0xFFD97706)
                              : const Color(0xFF10B981)),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _showSplash
                      ? _buildSplashScreen()
                      : _showResults
                          ? _buildResultsScreen()
                          : _buildQuizScreen(),
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    final questionCount = _quizData?.data?.length ?? 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.close, color: Color(0xFF1F2937), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Quiz Icon with gradient background
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF38026B),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38026B).withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Quiz Title
                Text(
                  widget.lessonName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Info Card
                Center(
                  child: SizedBox(
                    width: 200,
                    child: _buildInfoCard(
                      icon: Icons.help_outline_rounded,
                      title: '$questionCount',
                      subtitle: questionCount == 1 ? 'Question' : 'Questions',
                      color: const Color(0xFF38026B),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Instructions Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38026B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF38026B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionItem('Read each question carefully'),
                      const SizedBox(height: 8),
                      _buildInstructionItem('Select the best answer'),
                      const SizedBox(height: 8),
                      _buildInstructionItem('You can review your answers before submitting'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38026B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF38026B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizScreen() {
    if (_quizData?.data == null || _quizData!.data!.isEmpty) {
      return _buildEmptyState();
    }

    final question = _quizData!.data![_currentQuestionIndex];
    final totalQuestions = _quizData!.data!.length;
    final selectedAnswerIndex = _selectedAnswers[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / totalQuestions;
    final isFlashcard = question.type == QuestionType.oneAnswer;
    final showFlashcardAnswer = _flashcardAnswersShown[_currentQuestionIndex] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Question ${_currentQuestionIndex + 1} of $totalQuestions',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
                minHeight: 4,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Flashcard Design (for OneAnswer type)
                    if (isFlashcard) ...[
                      // Question Card (Front of Flashcard)
                      Container(
                        constraints: const BoxConstraints(minHeight: 250),
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF38026B).withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                              spreadRadius: -5,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Question image if available
                            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    ApiConfig.getImageUrl(question.imageUrl!),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                            // Question text
                            Text(
                              question.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                                height: 1.4,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Flip Button - inside question card
                            _buildFlipButton(question, showFlashcardAnswer, totalQuestions),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Regular Question Design (for MultipleChoice and TrueFalse)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Question image if available
                            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ApiConfig.getImageUrl(question.imageUrl!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 48,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Question text
                            Text(
                              question.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Answers (for MultipleChoice and TrueFalse types only)
                    if (!isFlashcard) ...[
                      ...question.answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final isSelected = selectedAnswerIndex == index;

                      Color borderColor = const Color(0xFFE5E7EB);
                      Color backgroundColor = Colors.white;
                      const Color textColor = Color(0xFF1F2937);
                      if (isSelected) {
                        borderColor = const Color(0xFF38026B);
                        backgroundColor = const Color(0xFF38026B).withOpacity(0.1);
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectAnswer(index),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: borderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFF38026B)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF38026B)
                                                : const Color(0xFF9CA3AF),
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          answer.text,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer with submit/next button
            SafeArea(
              top: false,
              minimum: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: isFlashcard
                    ? SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: showFlashcardAnswer
                              ? () {
                                  if (_currentQuestionIndex < totalQuestions - 1) {
                                    _nextQuestion();
                                  } else {
                                    _submitQuiz();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: showFlashcardAnswer
                                ? const Color(0xFF38026B)
                                : const Color(0xFFE5E7EB),
                            foregroundColor: Colors.white,
                            elevation: showFlashcardAnswer ? 4 : 0,
                            shadowColor: showFlashcardAnswer
                                ? const Color(0xFF38026B).withOpacity(0.4)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          icon: Icon(
                            _currentQuestionIndex < totalQuestions - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
                            size: 22,
                          ),
                          label: Text(
                            _currentQuestionIndex < totalQuestions - 1
                                ? 'Next Question'
                                : 'Submit Quiz',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: OutlinedButton.icon(
                                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF38026B),
                                  disabledForegroundColor: const Color(0xFF9CA3AF),
                                  side: BorderSide(
                                    color: _currentQuestionIndex > 0
                                        ? const Color(0xFF38026B)
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                label: const Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton.icon(
                                onPressed: selectedAnswerIndex != null
                                    ? () {
                                        if (_currentQuestionIndex < totalQuestions - 1) {
                                          _nextQuestion();
                                        } else {
                                          _submitQuiz();
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF38026B),
                                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(
                                  _currentQuestionIndex < totalQuestions - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.check_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  _currentQuestionIndex < totalQuestions - 1 ? 'Next' : 'Submit',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final quiz = _quizData!;
    final totalQuestions = quiz.data?.length ?? 0;
    final percentageDouble =
        totalQuestions > 0 ? (_score / totalQuestions) * 100 : 0.0;
    final percentageRounded = percentageDouble.round();
    final passDegree = quiz.passDegree;
    final passed = percentageDouble >= passDegree;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Score summary (optional per API)
                    if (quiz.isScoreDisplayed)
                      Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF38026B),
                              const Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38026B).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_score / $totalQuestions',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$percentageRounded% Score',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              passed
                                  ? 'Passed — meets ${_formatPassPercent(passDegree)}% requirement'
                                  : 'Not passed — need ${_formatPassPercent(passDegree)}% to unlock next lessons',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: passed
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFDE68A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: passed
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: passed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              passed ? Icons.check_circle : Icons.cancel,
                              color: passed
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                              size: 36,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                passed
                                    ? 'You passed. Required: ${_formatPassPercent(passDegree)}% to continue.'
                                    : 'Not passed. You need ${_formatPassPercent(passDegree)}% to unlock the next lessons.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (passed) ...[
                      const SizedBox(height: 12),
                      _buildMotivationBanner(percentageDouble),
                    ],

                    if (quiz.isAnswerDisplayed) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Review Your Answers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              color: Color(0xFF6B7280),
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Answer review is disabled for this quiz.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (quiz.isAnswerDisplayed)
                      ...List.generate(totalQuestions, (index) {
                      final question = _quizData!.data![index];
                      final userAnswerIndex = _selectedAnswers[index];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question image if available
                            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ApiConfig.getImageUrl(question.imageUrl!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 48,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              '${index + 1}. ${question.text}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            ...question.answers.asMap().entries.map((entry) {
                              final answerIndex = entry.key;
                              final answer = entry.value;
                              
                              // Determine styling based on answer status
                              bool isSelected = userAnswerIndex == answerIndex;
                              bool isCorrect = answer.isCorrect;
                              
                              Color borderColor = const Color(0xFF1193d4).withValues(alpha: 0.2);
                              Color backgroundColor = Colors.white;
                              Color textColor = const Color(0xFF1F2937);
                              IconData? statusIcon;
                              Color iconColor = Colors.transparent;
                              String statusText = '';

                              if (isSelected && isCorrect) {
                                // User selected correct answer
                                borderColor = const Color(0xFF10B981);
                                backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
                                statusIcon = Icons.check_circle;
                                iconColor = const Color(0xFF10B981);
                                statusText = 'Your answer - Correct';
                              } else if (isSelected && !isCorrect) {
                                // User selected wrong answer
                                borderColor = const Color(0xFFEF4444);
                                backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
                                statusIcon = Icons.cancel;
                                iconColor = const Color(0xFFEF4444);
                                statusText = 'Your answer - Incorrect';
                              } else if (!isSelected && isCorrect) {
                                // Correct answer not selected by user
                                borderColor = const Color(0xFF10B981);
                                backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
                                statusIcon = Icons.check_circle;
                                iconColor = const Color(0xFF10B981);
                                statusText = 'Correct answer';
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor, width: 2),
                                    ),
                                    child: Row(
                                      children: [
                                        if (statusIcon != null)
                                          Icon(statusIcon, color: iconColor, size: 24),
                                        if (statusIcon != null) const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                answer.text,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (statusText.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: iconColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Show reason under the correct answer
                                  if (isCorrect && question.reason != null && question.reason!.isNotEmpty) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF38026B).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF38026B).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.lightbulb_outline_rounded,
                                                  color: Color(0xFF38026B),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Explanation',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF38026B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            question.reason!,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF1F2937),
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            // Footer with two buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (quiz.isRetake) ...[
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _retakeQuiz,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38026B),
                              side: const BorderSide(
                                color: Color(0xFF38026B),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 22),
                            label: const Text(
                              'Retake',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Back to Course Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38026B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 22),
                          label: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading quiz...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Unknown error',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38026B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E7FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 48,
                  color: Color(0xFF38026B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Questions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This quiz does not contain any questions',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
