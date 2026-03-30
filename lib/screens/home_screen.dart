import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grade_model.dart';
import '../models/student_progress_stats.dart';
import '../services/auth_service.dart';
import '../services/section_grade_service.dart';
import '../services/statistics_service.dart';
import '../utils/app_theme.dart';
import '../config/api_config.dart';
import '../config/app_route_observer.dart';
import '../widgets/simple_statistics_card.dart';
import '../widgets/shimmer_statistics_card.dart';
import 'grade_courses_by_grade_screen.dart';
import 'login_screen.dart';
import 'enrolled_courses_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  int _selectedIndex = 0;
  
  // Grades with courses state
  final SectionGradeService _sectionGradeService = SectionGradeService();
  List<GradeWithCourses> _gradesWithCourses = [];
  bool _isLoadingGrades = true;
  String? _gradesError;

  // Student progress state
  StudentProgressStats? _progressStats;
  bool _isLoadingProgress = true;
  String? _progressError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _loadGradesWithCourses();
        _loadProgress();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // User navigated back to home — refresh data
    if (!mounted) return;
    _loadGradesWithCourses();
    _loadProgress();
  }

  Future<void> _loadGradesWithCourses() async {
    setState(() {
      _isLoadingGrades = true;
      _gradesError = null;
    });

    try {
      final grades = await _sectionGradeService.getGradesWithCourses();
      if (!mounted) return;
      setState(() {
        _gradesWithCourses = grades;
        _isLoadingGrades = false;
        _gradesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gradesWithCourses = [];
        _isLoadingGrades = false;
        _gradesError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadProgress() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;
    final user = authService.currentUser;

    if (token == null || user == null) {
      setState(() {
        _isLoadingProgress = false;
        _progressError = 'You must be logged in';
      });
      return;
    }

    setState(() {
      _isLoadingProgress = true;
      _progressError = null;
    });

    try {
      final stats = await StatisticsService.getStudentProgress(
        userId: user.id,
        token: token,
        authService: authService,
      );
      if (!mounted) return;
      setState(() {
        _progressStats = stats;
        _isLoadingProgress = false;
        _progressError = stats == null ? 'Failed to load progress' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressStats = null;
        _isLoadingProgress = false;
        _progressError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }


  void _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          _ProtectedEnrolledCoursesScreen(),
          const SettingsScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final isPortrait = screenSize.height > screenSize.width;
    final screenWidth = screenSize.width;
    final horizontalPadding = isTablet ? (screenWidth * 0.1).clamp(40.0, 120.0) : 20.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(right: 20, bottom: 16, left: 20),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: user?.imagePath != null && user!.imagePath!.isNotEmpty
                      ? NetworkImage(ApiConfig.getImageUrl(user!.imagePath!))
                      : null,
                  child: user?.imagePath == null
                      ? const Icon(Icons.person, color: AppTheme.primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.userName ?? "Student"} 👋',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'Ready to learn?',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF3E5F5),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),

        // Dr. Tamer Elsawy banner
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
            child: _buildDrBanner(),
          ),
        ),

        // Categories section — one row of cards (above progress)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoadingGrades)
                  const SizedBox(
                    height: 100,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_gradesError != null || _gradesWithCourses.isEmpty)
                  const SizedBox.shrink()
                else
                  Column(
                    children: List.generate(
                      _gradesWithCourses.length,
                      (index) {
                        final grade = _gradesWithCourses[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < _gradesWithCourses.length - 1 ? 12 : 0),
                          child: _CategoryCard(
                            gradeName: grade.name,
                            cardIndex: index,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GradeCoursesByGradeScreen(
                                    gradeIdOrName: grade.name,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Student progress section
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              if (_isLoadingProgress) {
                return const ShimmerStatisticsCard();
              }
              if (_progressStats == null) {
                // If progress fails, just show nothing to keep home clean
                return const SizedBox.shrink();
              }
              return SimpleStatisticsCard(stats: _progressStats!);
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // (hero section removed)

  Widget _buildDrBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38026B).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image — Dr. Tamer Elsawy
            Image.asset(
              'assets/Gemini_Generated_Image_1utakq1utakq1uta.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF38026B),
                child: const Center(
                  child: Icon(Icons.person, size: 48, color: Colors.white54),
                ),
              ),
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            // Title overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dr. Tamer Elsawy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your guide to excellence',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 520.0 : double.infinity;
    // Keep the bar above the device system nav / home indicator.
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: 16 + safeBottom),
        width: maxWidth,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(isTablet ? 26 : 22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 10 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0, isTablet),
              _buildNavItem(Icons.book_rounded, 'My courses', 1, isTablet),
              _buildNavItem(Icons.settings_rounded, 'Settings', 2, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isTablet) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF38026B).withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF38026B) : const Color(0xFF9CA3AF),
              size: isTablet ? 26 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: isTablet ? 12 : 11,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 18 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF38026B),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single category card — image-style with grade name overlay.
class _CategoryCard extends StatelessWidget {
  final String gradeName;
  final int cardIndex;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.gradeName,
    required this.cardIndex,
    required this.onTap,
  });

  static const List<List<Color>> _gradientPalettes = [
    [Color(0xFF38026B), Color(0xFF6A1B9A)], // purple
    [Color(0xFF1E3A5F), Color(0xFF3B82F6)], // blue
    [Color(0xFF134E4A), Color(0xFF0D9488)], // teal
    [Color(0xFF831843), Color(0xFFBE185D)], // pink
    [Color(0xFF78350F), Color(0xFFD97706)], // amber
    [Color(0xFF1E293B), Color(0xFF64748B)], // slate
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradientPalettes[cardIndex % _gradientPalettes.length];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image-like gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                    ),
                  ),
                  // Subtle overlay for depth
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                  // Grade name centered on card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Center(
                      child: Text(
                        gradeName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Small corner accent
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
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

// Simple wrapper widgets without screen protection
class _ProtectedEnrolledCoursesScreen extends StatelessWidget {
  const _ProtectedEnrolledCoursesScreen();

  @override
  Widget build(BuildContext context) {
    return const EnrolledCoursesScreen();
  }
}

