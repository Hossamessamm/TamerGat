import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../screens/subject_courses_screen.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final int index;

  const SubjectCard({super.key, required this.subject, this.index = 0});

  static const _pastelColors = [
    Color(0xFFBBDEFB), // pastel blue
    Color(0xFFF8BBD9), // pastel pink
    Color(0xFFC8E6C9), // pastel green
    Color(0xFFE1BEE7), // pastel purple
    Color(0xFFFFE0B2), // pastel orange
    Color(0xFFFFF9C4), // pastel yellow
    Color(0xFFB2DFDB), // pastel teal
    Color(0xFFD1C4E9), // pastel lavender
    Color(0xFFFFCCBC), // pastel peach
    Color(0xFFB3E5FC), // pastel sky blue
  ];
  static const _accentColors = [
    Color(0xFF38026B),
    Color(0xFF6A1B9A),
    Color(0xFF7B1FA2),
    Color(0xFF9C27B0),
    Color(0xFFAB47BC),
    Color(0xFF8E24AA),
    Color(0xFF4A148C),
    Color(0xFF6A1B9A),
    Color(0xFF7B1FA2),
    Color(0xFF38026B),
  ];

  Color get _pastelColor => _pastelColors[index % _pastelColors.length];
  Color get _accentColor => _accentColors[index % _accentColors.length];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cardMargin = isTablet ? 16.0 : 12.0;
    final padding = isTablet ? 20.0 : 16.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectCoursesScreen(subject: subject),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: cardMargin, vertical: cardMargin * 0.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored accent strip
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: _pastelColor,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _pastelColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: _accentColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subject.name.isNotEmpty ? subject.name : 'مادة بدون عنوان',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1F36),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subject.gradeName != null && subject.gradeName!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subject.gradeName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (subject.description != null && subject.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subject.description!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Arrow hint (points left in RTL for "view courses")
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
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
}
