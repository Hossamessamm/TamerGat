import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_progress_stats.dart';

class SimpleStatisticsCard extends StatefulWidget {
  final StudentProgressStats stats;

  const SimpleStatisticsCard({
    super.key,
    required this.stats,
  });

  @override
  State<SimpleStatisticsCard> createState() => _SimpleStatisticsCardState();
}

class _SimpleStatisticsCardState extends State<SimpleStatisticsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - progress section
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    // Decorative accent bar
                    Container(
                      width: 5,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B8FD9), Color(0xFF7B68C8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your progress',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1F36),
                              fontFamily: 'Cairo',
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B8FD9).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Track your learning',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7B68C8),
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Decorative icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B8FD9).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF7B68C8),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Stats Grid
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      value: widget.stats.totalCoursesEnrolled.toString(),
                      label: 'Courses',
                      sublabel: 'Enrolled',
                      color: const Color(0xFFB8E6E1),
                      icon: Icons.book_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      value: widget.stats.completedLessons.toString(),
                      label: 'Lessons',
                      sublabel: 'Completed',
                      color: const Color(0xFFFFD4B8),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Progress Card
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFE5D9),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          const Text(
                            'Completion rate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          '${widget.stats.completionPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9A76),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: widget.stats.completionPercentage / 100,
                        backgroundColor: const Color(0xFFFFE5D9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF9A76),
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.stats.completedLessons} of ${widget.stats.totalLessons} lessons',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quiz Score Card
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD9E5FF),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: widget.stats.averageQuizScore / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFD9E5FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF9B8FD9),
                              ),
                            ),
                          ),
                          Text(
                            '${widget.stats.averageQuizScore.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B8FD9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Average quiz score',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getPerformanceMessage(widget.stats.averageQuizScore),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
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

  Widget _buildStatBox({
    required String value,
    required String label,
    required String sublabel,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF2D3748),
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF718096),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage(double score) {
    if (score >= 90) {
      return 'Outstanding performance! 🌟';
    } else if (score >= 80) {
      return 'Great job! 👏';
    } else if (score >= 70) {
      return 'Good work, keep going! 💪';
    } else if (score >= 60) {
      return 'You can improve 📚';
    } else {
      return 'Review and try again 📖';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
