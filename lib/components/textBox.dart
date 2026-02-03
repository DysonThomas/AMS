import 'package:flutter/material.dart';

class MyTextBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool enabled;
  const MyTextBox({super.key, required this.controller, required this.label, this.obscureText = false,this.enabled=true});

  @override
  Widget build(BuildContext context) {
    return    TextField(
      enabled: enabled,
      obscureText: obscureText,
      controller: controller,
      style: TextStyle(
        color: Colors.black
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.grey, // 👈 label color
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
      ),
    );
  }
}
