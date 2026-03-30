import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _deepBlue = Color(0xFF0A1628);
  static const Color _royalBlue = Color(0xFF1E3A5F);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _deepBlue,
              _royalBlue,
              _deepBlue,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    // Softer final scale so the logo reads more “zoomed out”.
                    scale: value * 0.5,
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 150,
                        height: 150,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withValues(alpha: 0.06),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/Screenshot_2.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 70,
                                  color: _deepBlue,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Column(
                        children: [
                          const Text(
                            'GAT Maths',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tamer El-Sawy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _gold.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'EXP +20',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _gold.withValues(alpha: 0.95),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'GAT & SAAT 5000 student',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_gold),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


