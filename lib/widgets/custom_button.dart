import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  static const _deepBlue = Color(0xFF0A1628);
  static const _royalBlue = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : const LinearGradient(
          colors: [_deepBlue, _royalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: isOutlined ? Colors.transparent : null,
        borderRadius: radius,
        border: isOutlined ? Border.all(color: _deepBlue, width: 2) : null,
        boxShadow: isOutlined ? null : [
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
          onTap: isLoading ? null : onPressed,
          borderRadius: radius,
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isOutlined ? _deepBlue : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isOutlined ? _deepBlue : Colors.white,
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
}
