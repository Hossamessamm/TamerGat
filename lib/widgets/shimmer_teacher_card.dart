import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerTeacherCard extends StatelessWidget {
  const ShimmerTeacherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
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
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // Header Section
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
            ),

            // Content Card
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    // Teacher Name
                    Container(
                      width: 150,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subject
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Bio line 1
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Bio line 2
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
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
