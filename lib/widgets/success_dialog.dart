import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Continue',
    this.onPressed,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Continue',
    VoidCallback? onPressed,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4),
              Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF22C55E),
                    Color(0xFF16A34A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF052E16),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed ??
                    () {
                      Navigator.of(context).pop();
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

