import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _backgroundAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _deepBlue = Color(0xFF0A1628);
  static const Color _royalBlue = Color(0xFF1E3A5F);
  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _lightGold = Color(0xFFE8C547);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _backgroundAnimController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeOutCubic),
    );
    
    _contentAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _contentAnimController.reset();
    _contentAnimController.forward();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      4,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  void _navigateToLogin() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _navigateToRegister() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RegistrationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildHeroPage(),
                      _buildSkillDevelopmentPage(),
                      _buildAuthorityPage(),
                      _buildCompetitiveAdvantagePage(),
                      _buildCTAPage(),
                    ],
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _deepBlue,
                _royalBlue,
                _deepBlue.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(6, (index) => _buildFloatingMathSymbol(index)),
              _buildGlowingOrb(
                top: 100,
                right: -50,
                size: 200,
                color: _gold.withValues(alpha: 0.1),
              ),
              _buildGlowingOrb(
                bottom: 200,
                left: -80,
                size: 250,
                color: _accentBlue.withValues(alpha: 0.15),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingMathSymbol(int index) {
    final symbols = ['∑', '∫', 'π', '√', '∞', 'Δ'];
    final positions = [
      const Offset(0.1, 0.15),
      const Offset(0.85, 0.2),
      const Offset(0.15, 0.6),
      const Offset(0.9, 0.55),
      const Offset(0.5, 0.1),
      const Offset(0.7, 0.75),
    ];
    
    return AnimatedBuilder(
      animation: _backgroundAnimController,
      builder: (context, child) {
        final progress = (_backgroundAnimController.value + index * 0.15) % 1.0;
        final yOffset = math.sin(progress * 2 * math.pi) * 20;
        final opacity = 0.1 + math.sin(progress * math.pi) * 0.1;
        
        return Positioned(
          left: MediaQuery.of(context).size.width * positions[index].dx,
          top: MediaQuery.of(context).size.height * positions[index].dy + yOffset,
          child: Opacity(
            opacity: opacity,
            child: Text(
              symbols[index],
              style: TextStyle(
                fontSize: 32 + index * 4.0,
                color: index.isEven ? _gold : _white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/Screenshot_2.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _gold.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.school_rounded,
                          color: _gold,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GAT Maths',
                    style: TextStyle(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Tamer El-Sawy',
                    style: TextStyle(
                      color: _gold.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_currentPage < 4)
            TextButton(
              onPressed: _skipToEnd,
              child: Row(
                children: [
                  Text(
                    'Skip',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _white.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeroIllustration(),
              const SizedBox(height: 48),
              _buildGoldBadge('Excellence Awaits'),
              const SizedBox(height: 24),
              const Text(
                'The Highest Grades.\nGuaranteed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Start your journey toward excellence in GAT Maths with structured lessons and proven strategies.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _gold.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gold.withValues(alpha: 0.3),
                _lightGold.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: _gold.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '100%',
                style: TextStyle(
                  color: _gold,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TOP SCORE',
                  style: TextStyle(
                    color: _deepBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 20,
          child: _buildFloatingIcon(Icons.star_rounded, _gold, 28),
        ),
        Positioned(
          bottom: 20,
          left: 10,
          child: _buildFloatingIcon(Icons.emoji_events_rounded, _lightGold, 24),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, double size) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildGoldBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.2),
            _lightGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: _gold, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillDevelopmentPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBrainIllustration(),
              _buildGoldBadge('Skill Building'),
              const Text(
                'Master Reasoning &\nProblem Solving',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Develop logical thinking, creativity, and analytical skills for success in Science, Technology, and Engineering.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
              _buildSkillChips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrainIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _accentBlue.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _accentBlue.withValues(alpha: 0.3),
                _royalBlue.withValues(alpha: 0.2),
              ],
            ),
            border: Border.all(
              color: _accentBlue.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.psychology_rounded,
            color: _white,
            size: 56,
          ),
        ),
        ..._buildOrbitingSymbols(),
      ],
    );
  }

  List<Widget> _buildOrbitingSymbols() {
    final symbols = ['∑', '÷', '×', 'π'];
    final angles = [0.0, 90.0, 180.0, 270.0];
    
    return List.generate(4, (index) {
      final angle = (angles[index] + _backgroundAnimController.value * 360) * math.pi / 180;
      final radius = 85.0;
      
      return AnimatedBuilder(
        animation: _backgroundAnimController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              math.cos(angle) * radius,
              math.sin(angle) * radius,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _deepBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  symbols[index],
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSkillChips() {
    final skills = ['Logical Thinking', 'Creativity', 'Analytics'];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: _gold,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                skill,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAuthorityPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExpertProfile(),
              _buildGoldBadge('Certified Expert'),
              const Text(
                'Learn From a Certified\nGAT Expert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Certified GAT consultant and trainer since 2008. Hundreds of students achieved top scores, including 100%.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
              _buildTrustIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpertProfile() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _gold.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _royalBlue,
                _deepBlue,
              ],
            ),
            border: Border.all(
              color: _gold,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: _white,
            size: 60,
          ),
        ),
        Positioned(
          bottom: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, _lightGold],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: _deepBlue, size: 14),
                SizedBox(width: 4),
                Text(
                  'Since 2008',
                  style: TextStyle(
                    color: _deepBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatCard('+20', 'EXP'),
        const SizedBox(width: 16),
        _buildStatCard('100%', 'Top Scores'),
        const SizedBox(width: 16),
        _buildStatCard(
          '5000',
          'GAT & SAAT\nstudent',
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveAdvantagePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTajmeatIllustration(),
              _buildWeeklyBadge(),
              const Text(
                'Exclusive Weekly\nUpdated Tajmeat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'The first trainer to create structured Tajmeat collections — updated weekly with new GAT questions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
              _buildFeatureHighlights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTajmeatIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _accentBlue.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: _white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _gold.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_rounded,
                color: _gold,
                size: 40,
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 30,
          child: _buildNotificationBubble(),
        ),
      ],
    );
  }

  Widget _buildNotificationBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_gold, _lightGold],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_rounded, color: _deepBlue, size: 14),
          SizedBox(width: 4),
          Text(
            'NEW',
            style: TextStyle(
              color: _deepBlue,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentBlue.withValues(alpha: 0.3),
            _royalBlue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentBlue.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.update_rounded, color: _deepBlue, size: 12),
          ),
          const SizedBox(width: 8),
          const Text(
            'Updated Weekly',
            style: TextStyle(
              color: _white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    final features = [
      {'icon': Icons.first_page_rounded, 'text': 'First in KSA'},
      {'icon': Icons.refresh_rounded, 'text': 'Weekly Updates'},
      {'icon': Icons.quiz_rounded, 'text': 'Real Questions'},
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: _gold,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature['text'] as String,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTAPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCTAIllustration(),
              const SizedBox(height: 48),
              const Text(
                'Start Preparing\nToday',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Join thousands of students achieving their dream scores',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildPrimaryButton(
                'Create Account',
                Icons.person_add_rounded,
                _navigateToRegister,
              ),
              const SizedBox(height: 16),
              _buildSecondaryButton(
                'Login',
                Icons.login_rounded,
                _navigateToLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTAIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _gold.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gold, _lightGold],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            color: _deepBlue,
            size: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _white.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: _deepBlue.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _deepBlue, size: 22),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: _deepBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: _white.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _white, size: 22),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          _buildPageIndicator(),
          if (_currentPage < 4) ...[
            const SizedBox(height: 24),
            _buildNextButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _gold : _white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _white.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _nextPage,
            borderRadius: BorderRadius.circular(16),
            splashColor: _deepBlue.withValues(alpha: 0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: _deepBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: _deepBlue, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
