import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool useWhiteStyle;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.useWhiteStyle = false,
  });

  static const _fill = Color(0xFFF1F5F9);
  static const _fillWhite = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _focus = Color(0xFF0A1628);
  static const _focusBlue = Color(0xFF0A1628);
  static const _hint = Color(0xFF94A3B8);
  static const _text = Color(0xFF0F172A);
  static const _error = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final fill = useWhiteStyle ? _fillWhite : _fill;
    final focus = useWhiteStyle ? _focusBlue : _focus;
    return Container(
      decoration: useWhiteStyle
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontSize: 16,
          color: _text,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint ?? label,
          hintStyle: const TextStyle(color: _hint, fontSize: 15, fontWeight: FontWeight.w400),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: useWhiteStyle ? const Color(0xFFE0E0E0) : _border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: focus, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _error, width: 2),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _hint, size: 22)
              : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
