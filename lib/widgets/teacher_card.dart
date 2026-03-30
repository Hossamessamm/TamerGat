import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../config/api_config.dart';

class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.15),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          children: [
            // Enhanced Header Section
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  // Gradient Background
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                            Color(0xFFF093FB),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating Elements
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 40,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Teacher Profile Image
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 0),
                        height: 280, 
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                image: teacher.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(ApiConfig.getImageUrl(teacher.imageUrl)),
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                      )
                                    : null,
                              ),
                              child: teacher.imageUrl.isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            // Gradient overlay at bottom to blend with card
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.5),
                                    Colors.white,
                                  ],
                                ),
                              ),
                            ),
                            // Online Status Ring
                            if (teacher.isOnline)
                              Positioned(
                                bottom: 50,
                                right: 20,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF667EEA),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Premium Badge
                  if (teacher.isPremium)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF667EEA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Enhanced Content Card
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Teacher Info
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Only show subject if it exists and is not empty
                    if (teacher.subject != null && teacher.subject!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        teacher.subject!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      teacher.bio.isNotEmpty ? teacher.bio : 'معلم متميز في التعليم',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'الدخول للدورات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}
