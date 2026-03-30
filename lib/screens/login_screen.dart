import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/error_dialog.dart';
import '../utils/error_messages.dart';
import 'registration_screen.dart';
import '../app_keys.dart';
import '../models/dtos/login_request_dto.dart';
import '../services/payment_deep_link_controller.dart';
import 'home_screen.dart';
import 'payment_result_screen.dart';

const _deepBlue = Color(0xFF0A1628);
const _royalBlue = Color(0xFF1E3A5F);
const _gold = Color(0xFFD4AF37);
const _lightGold = Color(0xFFE8C547);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailOrMobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/01559158656');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final loginDto = LoginRequestDto.student(
      emailOrMobile: _emailOrMobileController.text.trim(),
      password: _passwordController.text,
    );
    final error = await authService.login(loginDto);

    if (!mounted) return;

    if (error == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final isAuthAfterDelay = authService.isAuthenticated;

      if (isAuthAfterDelay) {
        final pendingOrderId =
            await PaymentDeepLinkController.consumePendingOrderIdAfterAuth();
        if (!mounted) return;
        if (pendingOrderId != null && pendingOrderId.isNotEmpty) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appNavigatorKey.currentState?.push(
              MaterialPageRoute<void>(
                builder: (_) => PaymentResultScreen(orderId: pendingOrderId),
              ),
            );
          });
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (!isAuthAfterDelay) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final translatedMessage = ErrorMessages.translate(error);
      final errorTitle = ErrorMessages.getErrorTitle(error);
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ErrorDialog(title: errorTitle, message: translatedMessage),
      );
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support to reset your password')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isWide = MediaQuery.of(context).size.width >= 500;
    final padding = isWide ? 48.0 : 24.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFAFBFF),
                Color(0xFFF8FAFC),
                Colors.white,
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _deepBlue.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: isWide ? 48 : 36),
                              _buildLogoSection(),
                              const SizedBox(height: 28),
                              _buildTitleSection(),
                              const SizedBox(height: 32),
                              _buildFormCard(authService),
                              const SizedBox(height: 28),
                              _buildSignUpLink(),
                              const SizedBox(height: 32),
                              _buildFooter(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/Screenshot_2.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_deepBlue, _royalBlue],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your learning journey',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _deepBlue.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabeledField(
              label: 'Email or Phone',
              child: CustomTextField(
                label: 'Enter your email or phone number',
                controller: _emailOrMobileController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.person_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email or phone number';
                  }
                  final isEmail = value.contains('@');
                  final isPhone = RegExp(r'^01[0-9]{9}$').hasMatch(value);
                  if (!isEmail && !isPhone) {
                    return 'Enter a valid email or phone number';
                  }
                  return null;
                },
                useWhiteStyle: true,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabeledField(
              label: 'Password',
              trailing: GestureDetector(
                onTap: _onForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: _deepBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: CustomTextField(
                label: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 22,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                useWhiteStyle: true,
              ),
            ),
            const SizedBox(height: 28),
            _buildSignInButton(authService),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: trailing != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    trailing,
                  ],
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
        ),
        child,
      ],
    );
  }

  Widget _buildSignInButton(AuthService authService) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepBlue, _royalBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authService.isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Center(
            child: authService.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: _deepBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _deepBlue.withValues(alpha: 0.1), width: 1),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _deepBlue,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _deepBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: _openWhatsApp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAT Maths • ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Tamer El-Sawy',
                  style: TextStyle(
                    color: _deepBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
