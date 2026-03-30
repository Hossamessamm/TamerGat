import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_progress_stats.dart';
import '../utils/app_theme.dart';

class StatisticsCard extends StatefulWidget {
  final StudentProgressStats stats;

  const StatisticsCard({
    super.key,
    required this.stats,
  });

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إحصائيات التقدم',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                'تتبع أدائك الدراسي',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.book_rounded,
                            value: widget.stats.totalCoursesEnrolled.toString(),
                            label: 'Courses',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.task_alt_rounded,
                            value: widget.stats.completedLessons.toString(),
                            label: 'الدروس المكتملة',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.trending_up_rounded,
                            value: '${widget.stats.completionPercentage.toStringAsFixed(0)}%',
                            label: 'نسبة الإنجاز',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.star_rounded,
                            value: '${widget.stats.averageQuizScore.toStringAsFixed(0)}%',
                            label: 'متوسط الاختبارات',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Progress Charts Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildProgressChart(),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildQuizScoreChart(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final completionPercent = widget.stats.completionPercentage;
    
    return Column(
      children: [
        const Text(
          'نسبة الإنجاز',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  value: completionPercent,
                  color: const Color(0xFF4CAF50),
                  title: '${completionPercent.toStringAsFixed(0)}%',
                  radius: 35,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: 100 - completionPercent,
                  color: Colors.white.withOpacity(0.2),
                  title: '',
                  radius: 30,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.stats.completedLessons} من ${widget.stats.totalLessons}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildQuizScoreChart() {
    final quizScore = widget.stats.averageQuizScore;
    
    return Column(
      children: [
        const Text(
          'متوسط الاختبارات',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  value: quizScore,
                  color: const Color(0xFFFFB74D),
                  title: '${quizScore.toStringAsFixed(0)}%',
                  radius: 35,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: 100 - quizScore,
                  color: Colors.white.withOpacity(0.2),
                  title: '',
                  radius: 30,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          quizScore >= 70 ? 'أداء ممتاز!' : 'استمر في التحسن',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
