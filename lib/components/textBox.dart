import 'package:flutter/material.dart';

class MyTextBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const MyTextBox({super.key, required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return    TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
