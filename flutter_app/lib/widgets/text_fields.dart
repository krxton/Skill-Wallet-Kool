import 'package:flutter/material.dart';

class SWKTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged; // <-- เพิ่ม
  final bool obscureText;
  final Widget? suffix;

  const SWKTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.onChanged,       // <-- เพิ่ม
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,            // <-- ส่งต่อ
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}
