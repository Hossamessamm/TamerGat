import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_progress_stats.dart';

class DetailedStatisticsWidget extends StatefulWidget {
  final StudentProgressStats stats;

  const DetailedStatisticsWidget({
    super.key,
    required this.stats,
  });

  @override
  State<DetailedStatisticsWidget> createState() => _DetailedStatisticsWidgetState();
}

class _DetailedStatisticsWidgetState extends State<DetailedStatisticsWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tabs
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF667EEA),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'تحليل مفصل',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tab selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTab('نظرة عامة', 0),
                      ),
                      Expanded(
                        child: _buildTab('الأداء', 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content based on selected tab
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _selectedTab == 0
                ? _buildOverviewTab()
                : _buildPerformanceTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF8F92A1),
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar chart
        const Text(
          'التقدم في الدروس',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1F36),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: widget.stats.totalLessons.toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'مكتمل',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: Color(0xFF8F92A1),
                              ),
                            ),
                          );
                        case 1:
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'متبقي',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: Color(0xFF8F92A1),
                              ),
                            ),
                          );
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8F92A1),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: widget.stats.totalLessons / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: widget.stats.completedLessons.toDouble(),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: (widget.stats.totalLessons - widget.stats.completedLessons).toDouble(),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Last activity info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر نشاط',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8F92A1),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.stats.lastActivity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance metrics
        _buildPerformanceMetric(
          'نسبة الإنجاز',
          widget.stats.completionPercentage,
          const Color(0xFF4CAF50),
          Icons.trending_up_rounded,
        ),
        const SizedBox(height: 16),
        
        _buildPerformanceMetric(
          'متوسط درجات الاختبارات',
          widget.stats.averageQuizScore,
          const Color(0xFFFFB74D),
          Icons.star_rounded,
        ),
        const SizedBox(height: 24),
        
        // Performance insights
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA).withOpacity(0.1),
                const Color(0xFF764BA2).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF667EEA).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFF667EEA),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'نصائح للتحسين',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInsight(widget.stats),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F36),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsight(StudentProgressStats stats) {
    String insight;
    IconData icon;
    
    if (stats.averageQuizScore >= 80 && stats.completionPercentage >= 70) {
      insight = 'أداء رائع! استمر في هذا المستوى المتميز 🌟';
      icon = Icons.emoji_events_rounded;
    } else if (stats.averageQuizScore < 70) {
      insight = 'حاول مراجعة المواد قبل الاختبارات لتحسين درجاتك 📚';
      icon = Icons.menu_book_rounded;
    } else if (stats.completionPercentage < 50) {
      insight = 'خصص وقتاً يومياً لإكمال المزيد من الدروس 📅';
      icon = Icons.schedule_rounded;
    } else {
      insight = 'أنت على الطريق الصحيح، استمر في التقدم! 💪';
      icon = Icons.trending_up_rounded;
    }
    
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF667EEA),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            insight,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1F36),
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
