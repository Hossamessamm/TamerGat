import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../services/contact_service.dart';

class EnrollmentDialog extends StatefulWidget {
  final String courseId;
  final String? teacherId;
  final String? teacherName;
  final Function() onEnrollmentSuccess;

  const EnrollmentDialog({
    super.key,
    required this.courseId,
    this.teacherId,
    this.teacherName,
    required this.onEnrollmentSuccess,
  });

  @override
  State<EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<EnrollmentDialog> {
  bool _showCodeInput = false;
  bool _loading = false;
  bool _success = false;
  String? _error;
  String? _whatsappNumber;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWhatsApp();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchWhatsApp() async {
    debugPrint('Starting _fetchWhatsApp');
    try {
      debugPrint('Calling ContactService.getAllContacts...');
      final response = await ContactService.getAllContacts();
      debugPrint('ContactService returned: $response');

      if (response != null && response.contacts.isNotEmpty) {
        // Get the first contact with a WhatsApp number
        final contact = response.contacts.firstWhere(
          (c) => c.whatsAppNumber != null && c.whatsAppNumber!.isNotEmpty,
          orElse: () => response.contacts.first,
        );

        debugPrint('Selected contact WhatsApp: ${contact.whatsAppNumber}');
        
        if (contact.whatsAppNumber != null && contact.whatsAppNumber!.isNotEmpty) {
          setState(() {
            _whatsappNumber = contact.whatsAppNumber;
          });
        }
      } else {
        debugPrint('No contacts found in response');
      }
    } catch (e) {
      debugPrint('Error fetching WhatsApp: $e');
    }
  }

  Future<void> _handleWhatsApp() async {
    if (_whatsappNumber == null) {
      setState(() => _error = 'WhatsApp number is not available at the moment');
      return;
    }

    final message = Uri.encodeComponent('Hello, I would like to inquire about course enrollment');
    
    // Try whatsapp:// scheme first (better for Android)
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$_whatsappNumber&text=$message');
    
    // Fallback to https://wa.me/
    final webUrl = Uri.parse('https://wa.me/$_whatsappNumber?text=$message');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        // Force launch web URL even if canLaunchUrl returns false
        // This handles cases where the browser is available but not explicitly queried
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      setState(() => _error = 'Unable to open WhatsApp application');
    }
  }

  Future<void> _handleSubmit() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the enrollment code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token == null) {
        setState(() {
          _loading = false;
          _error = 'Please login first';
        });
        return;
      }

      final response = await CourseService.enrollInCourse(
        studentId: authService.currentUser!.id,
        code: _codeController.text.trim(),
        token: authService.token!,
      );
      
      if (mounted) {
        if (response.success) {
          setState(() {
            _loading = false;
            _success = true;
          });
        } else {
          setState(() {
            _loading = false;
            _error = response.message ?? 'Invalid enrollment code';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'An error occurred while enrolling in the course';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'Course Enrollment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance space
                ],
              ),
            ),
            
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_success) return _buildSuccessView();
    if (_showCodeInput) return _buildInputView();
    return _buildSelectionView();
  }

  Widget _buildSelectionView() {
    return Column(
      key: const ValueKey('selection'),
      children: [
        const Text(
          'How would you like to join?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the method that works best for you',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        _buildOptionCard(
          icon: Icons.vpn_key_rounded,
          title: 'I have an activation code',
          subtitle: 'Enter the code you received',
          color: AppTheme.primaryColor,
          onTap: () => setState(() => _showCodeInput = true),
        ),
        
        const SizedBox(height: 16),
        
        _buildOptionCard(
          icon: Icons.chat_bubble_outline_sharp,
          title: 'Contact supervision',
          subtitle: 'To purchase a code or inquire, contact via WhatsApp',
          color: const Color(0xFF10B981), // Green for WhatsApp
          onTap: _handleWhatsApp,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, 
                size: 16, 
                color: Colors.grey.withOpacity(0.5)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showCodeInput = false;
                  _error = null;
                  _codeController.clear();
                });
              },
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: const Color(0xFF6B7280),
            ),
            const Expanded(
              child: Text(
                'Enter Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 40), // Balance space on the left
          ],
        ),
        const SizedBox(height: 24),
        
        TextField(
          controller: _codeController,
          enabled: !_loading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX-XXXX',
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorText: _error,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          onSubmitted: (_) => !_loading ? _handleSubmit() : null,
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _loading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Activate Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 48, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enrollment Successful!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'You can now access all course content',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: () {
            widget.onEnrollmentSuccess();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 50),
            elevation: 0,
          ),
          child: const Text(
            'Start Learning',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }
}
