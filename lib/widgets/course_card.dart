import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../screens/course_details_screen.dart';
import '../config/api_config.dart';

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isLargeTablet = size.width >= 900;
    
    // Responsive sizing
    final cardMargin = isTablet ? 16.0 : 12.0;
    final cardRadius = isTablet ? 48.0 : 40.0;
    final bottomPadding = isTablet ? 24.0 : 20.0;
    final aspectRatio = isTablet ? 16 / 10 : 16 / 12;
    final iconSize = isTablet ? 100.0 : 80.0;
    final contentMargin = isTablet ? 32.0 : 24.0;
    final contentPadding = isTablet ? 20.0 : 12.0;
    final contentRadius = isTablet ? 24.0 : 20.0;
    final titleFontSize = isTablet ? 20.0 : 16.0;
    final descFontSize = isTablet ? 14.0 : 11.0;
    final buttonHeight = isTablet ? 52.0 : 44.0;
    final buttonIconSize = isTablet ? 22.0 : 18.0;
    final buttonFontSize = isTablet ? 14.0 : 12.0;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(course: course),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: cardMargin * 0.67,
          horizontal: cardMargin,
        ),
        constraints: isLargeTablet 
            ? const BoxConstraints(maxWidth: 500)
            : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.15),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Enhanced Header Section with Responsive Aspect Ratio
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  children: [
                    // White Background
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(cardRadius),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Course Image
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(cardRadius),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            image: _hasValidImage()
                                ? DecorationImage(
                                    image: NetworkImage(_getFullImageUrl(course.imagePath!)),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  )
                                : null,
                          ),
                          child: !_hasValidImage()
                              ? Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Content Card
              Transform.translate(
                offset: Offset(0, isTablet ? -24 : -20),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: contentMargin),
                  padding: EdgeInsets.all(contentPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(contentRadius),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Course Title
                      Text(
                        course.courseName.isNotEmpty ? course.courseName : 'Untitled course',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      
                      // Description - Full text without truncation
                      if (course.description != null && course.description!.isNotEmpty)
                        Text(
                          course.description!,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (course.description != null && course.description!.isNotEmpty)
                        SizedBox(height: isTablet ? 12 : 6),
                      
                      // Price
                      if (course.price != null) ...[
                        SizedBox(height: isTablet ? 8 : 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.paid_rounded, size: descFontSize + 2, color: const Color(0xFF38026B)),
                            SizedBox(width: isTablet ? 6 : 4),
                            Text(
                              course.price! == 0
                                  ? 'Free'
                                  : '${course.price!.toStringAsFixed(2)} EGP',
                              style: TextStyle(
                                fontSize: descFontSize + 1,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF38026B),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      SizedBox(height: isTablet ? 12 : 8),
                      
                      // View Details Button
                      Container(
                        width: double.infinity,
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(contentRadius * 0.67),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF38026B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
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
                                  builder: (context) => CourseDetailsScreen(course: course),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(contentRadius * 0.67),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: buttonIconSize,
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  'View details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom padding to account for overlapping content card
              SizedBox(height: isTablet ? 24 : 20),
            ],
          ),
        ),
      );
  }

  bool _hasValidImage() {
    if (course.imagePath == null || course.imagePath!.isEmpty) {
      return false;
    }
    try {
      final fullUrl = _getFullImageUrl(course.imagePath!);
      return fullUrl.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _getFullImageUrl(String path) {
    try {
      return ApiConfig.getImageUrl(path);
    } catch (e) {
      return '';
    }
  }
}