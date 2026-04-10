import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_config_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/success_dialog.dart';
import '../models/dtos/register_request_dto.dart';
import 'login_screen.dart';

const _deepBlue = Color(0xFF0A1628);
const _royalBlue = Color(0xFF1E3A5F);
const _gold = Color(0xFFD4AF37);

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Sign In / back: [pop] when signup was pushed on top of login; otherwise replace
  /// with login (e.g. after onboarding used [pushReplacement] so there is nothing to pop).
  void _goToLogin() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _parentPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      final registerDto = RegisterRequestDto(
        userName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        phoneNumber: _phoneNumberController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isNotEmpty
            ? _parentPhoneController.text.trim()
            : null,
        academicYear: null,
        sectionId: null,
        gradeId: null,
        urologyBoard: null,
        nationality: null,
        country: null,
        hospital: null,
      );

      final error = await authService.register(registerDto);

      if (!mounted) return;

      if (error == null) {
        await SuccessDialog.show(
          context: context,
          title: 'Registration Successful',
          message:
              'Your account has been created.\nYou can now sign in with your credentials.',
          buttonText: 'Go to Sign In',
          onPressed: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
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
              colors: [Color(0xFFFAFBFF), Color(0xFFF8FAFC), Colors.white],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: _deepBlue,
                        ),
                        onPressed: _goToLogin,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/Screenshot_2.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_deepBlue, _royalBlue],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.school_rounded,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _deepBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your details to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: _deepBlue.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    CustomTextField(
                                      label: 'Full Name',
                                      controller: _nameController,
                                      prefixIcon: Icons.person_outlined,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please enter your name'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    CustomTextField(
                                      label: 'Email',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.email_outlined,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    Consumer<AppConfigService>(
                                      builder: (context, appConfig, _) =>
                                          appConfig.isInReviewVersionEqual()
                                          ? const SizedBox.shrink()
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 14),
                                                CustomTextField(
                                                  label: 'Phone Number',
                                                  controller:
                                                      _phoneNumberController,
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  prefixIcon:
                                                      Icons.phone_outlined,
                                                  validator: (v) {
                                                    if (v == null ||
                                                        v.isEmpty) {
                                                      return 'Please enter your phone number';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 14),
                                                CustomTextField(
                                                  label: 'Parent Phone Number',
                                                  controller:
                                                      _parentPhoneController,
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  prefixIcon: Icons
                                                      .phone_android_outlined,
                                                  validator: (v) {
                                                    if (v == null ||
                                                        v.isEmpty) {
                                                      return 'Please enter parent phone number';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: 14),
                                    CustomTextField(
                                      label: 'Password',
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
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Please enter your password';
                                        if (v.length < 6)
                                          return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    CustomTextField(
                                      label: 'Confirm Password',
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      prefixIcon: Icons.lock_outlined,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF94A3B8),
                                          size: 22,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Please confirm your password';
                                        if (v != _passwordController.text)
                                          return 'Passwords do not match';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    CustomButton(
                                      text: 'Create Account',
                                      onPressed: _handleRegister,
                                      isLoading: authService.isLoading,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _goToLogin,
                                          child: const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: _deepBlue,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
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
    );
  }
}
